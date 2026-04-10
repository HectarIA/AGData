import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

// Importações de páginas
import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/auth/presentation/pages/super_admin_page.dart';
import 'features/auth/presentation/pages/admin_page.dart';
import 'features/diagnostico/presentation/pages/selecao_talhao_screen.dart';
import 'features/auth/presentation/pages/change_password_page.dart';


import 'features/auth/data/models/auth_model.dart'; 
import 'features/auth/presentation/controller/session_controller.dart';
import 'features/diagnostico/data/datasources/database_service.dart';
import 'infra/repositories/sync_repository.dart';
import 'infra/services/connectivity_service.dart';
import 'core/theme/app_theme.dart'; 
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await DatabaseService.initialize();
      await di.init();
      final syncRepo = sl<SyncRepository>();
      await syncRepo.sincronizarLeituras();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Erro ao carregar arquivo .env: $e');
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN']; 
      options.tracesSampleRate = 1.0;
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;
    },
    appRunner: () async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      try {
        await DatabaseService.initialize();
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      await di.init();

      try {
        await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
        await Workmanager().registerPeriodicTask(
          "sync-task-id",
          "syncTask",
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
      } catch (e) {
        debugPrint('Erro no Workmanager: $e');
      }

      sl<ConnectivityService>().configurarOuvinteDeSincronizacao();
      _dispararSincronizacaoAutomatica();

      runApp(SentryWidget(child: const AGDataApp()));
    },
  );
}

void _dispararSincronizacaoAutomatica() async {
  final syncRepo = sl<SyncRepository>(); 
  try {
    await syncRepo.sincronizarLeituras();
  } catch (e, stackTrace) {
    await Sentry.captureException(e, stackTrace: stackTrace);
  }
}

// --- O WRAPPER DE AUTENTICAÇÃO ---
// Esta classe é responsável por decidir qual a tela inicial do app
// --- O WRAPPER DE AUTENTICAÇÃO ATUALIZADO ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Estado de carregamento inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        // 2. Se NÃO houver usuário no FirebaseAuth
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // 3. Verificamos os dados no Firestore
        return FutureBuilder<bool>(
          future: _inicializarSessaoReal(snapshot.data!.uid),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.green)),
              );
            }

            if (sessionSnapshot.data == false) {
              return const LoginPage();
            }

            final session = sl<SessionController>();
            final usuario = session.usuario; // Pegamos o usuário da sessão

            // ---------------------------------------------------------
            // 4. NOVA LÓGICA: Verificação de Senha Obrigatória
            // ---------------------------------------------------------
            // Se o usuário precisa trocar a senha, ele não passa daqui, 
            // independente da Role (SuperAdmin ou Admin).
            if (usuario != null && usuario.needsPasswordChange) {
              return const ChangePasswordPage();
            }

            // 5. Redirecionamento por Perfil (Role) - Apenas se não precisar trocar senha
            if (usuario?.role == UserRole.superAdmin) {
              return const SuperAdminPage();
            } else if (usuario?.role == UserRole.admin) {
              return const AdminPage();
            } else {
              return const SelecaoTalhaoScreen();
            }
          },
        );
      },
    );
  }

  // O método _inicializarSessaoReal permanece o mesmo que você já tem...
  Future<bool> _inicializarSessaoReal(String uid) async {
    final session = sl<SessionController>();
    try {
      if (session.usuario != null) return true;
      await session.inicializarUsuario(); 
      if (session.usuario == null) {
        await FirebaseAuth.instance.signOut();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Erro fatal na carga da sessão: $e");
      await FirebaseAuth.instance.signOut();
      return false;
    }
  }
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      theme: AppTheme.lightTheme,
      
      // A rota inicial '/' agora é controlada pelo AuthWrapper
      home: const AuthWrapper(), 

      routes: {
        '/login': (context) => const LoginPage(),
        '/super-admin': (context) => const SuperAdminPage(),
        '/admin': (context) => const AdminPage(),
        '/selecao-talhao': (context) => const SelecaoTalhaoScreen(),
      },
    );
  }
}