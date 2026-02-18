import 'package:flutter/material.dart';
import 'screens/selecao_talhao_screen.dart'; // <--- Importe a tela de seleção
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
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
      // Mudei de HomeScreen() para SelecaoTalhaoScreen()
      home: SelecaoTalhaoScreen(), 
    );
  }
}