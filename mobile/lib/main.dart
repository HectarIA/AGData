import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/pages/login_page.dart'; 
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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
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
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase inicializado.');
      } catch (e, stackTrace) {
        debugPrint('Erro ao inicializar Firebase: $e');
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      try {
        await DatabaseService.initialize();
        debugPrint('Banco de dados Isar inicializado.');
      } catch (e, stackTrace) {
        debugPrint('Erro ao inicializar Isar: $e');
        await Sentry.captureException(e, stackTrace: stackTrace);
      }

      await di.init();

      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: true,
        );
        
        await Workmanager().registerPeriodicTask(
          "sync-task-id",
          "syncTask",
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
        debugPrint('Workmanager inicializado.');
      } catch (e) {
        debugPrint('Erro ao inicializar Workmanager: $e');
      }

      sl<ConnectivityService>().configurarOuvinteDeSincronizacao();

      _dispararSincronizacaoAutomatica();

      runApp(
        SentryWidget(
          child: const AGDataApp(),
        ),
      );
    },
  );
}

void _dispararSincronizacaoAutomatica() async {
  final syncRepo = sl<SyncRepository>(); 
  try {
    await syncRepo.sincronizarLeituras();
    debugPrint('[AUTO-SYNC] Sincronização inicial finalizada.');
  } catch (e, stackTrace) {
    debugPrint('[AUTO-SYNC] Falha na sincronização automática: $e');
    await Sentry.captureException(e, stackTrace: stackTrace);
  }
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      home: const LoginPage(), 
      theme: AppTheme.lightTheme,
    );
  }
}