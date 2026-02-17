import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';


void main() async {
  // Garante que o Flutter e os plugins nativos estão prontos antes de iniciar
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicia o Isar Database!
  await DatabaseService.initialize(); 

  runApp(const AGDataApp());
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      home: HomeScreen(), 
    );
  }
}