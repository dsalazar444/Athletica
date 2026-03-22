import 'package:flutter/material.dart';
import 'views/auth/register_flow_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athletica',
      debugShowCheckedModeBanner: false,
      home: const RegisterFlowScreen(), 
    );
  }
}