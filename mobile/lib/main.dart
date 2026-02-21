import 'package:flutter/material.dart';
import 'screens/selecao_talhao_screen.dart'; 
import 'services/database_service.dart';
import 'core/theme/app_theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await DatabaseService.initialize(); 

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