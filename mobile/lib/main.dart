import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/diagnostico/presentation/pages/selecao_talhao_screen.dart'; 
import 'features/diagnostico/data/datasources/database_service.dart';
import 'core/theme/app_theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado.');
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
  }

  try {
    await DatabaseService.initialize();
    debugPrint('Banco de dados Isar inicializado.');
  } catch (e) {
    debugPrint('Erro ao inicializar Isar: $e');
  }

  runApp(const AGDataApp());
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      home: const SelecaoTalhaoScreen(), 
      theme: AppTheme.lightTheme,
    );
  }
}