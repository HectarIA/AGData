import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Importe a sua nova tela

void main() {
  runApp(const AGDataApp());
}

class AGDataApp extends StatelessWidget {
  const AGDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGdata',
      // Aqui futuramente você pode colocar o Theme global do app
      home: HomeScreen(), 
    );
  }
}