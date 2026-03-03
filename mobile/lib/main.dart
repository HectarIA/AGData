import 'package:flutter/material.dart';
import 'features/diagnostico/presentation/pages/selecao_talhao_screen.dart'; 
import 'features/diagnostico/data/datasources/database_service.dart';
import 'core/theme/app_theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  try {
    await DatabaseService.initialize();
    debugPrint('✅ Banco de dados Isar inicializado.');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar Isar: $e');
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