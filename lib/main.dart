import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'providers/judoka_provider.dart';
import 'providers/groupe_provider.dart';
import 'providers/seance_provider.dart'; // Importer le nouveau provider

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => JudokaProvider()),
        ChangeNotifierProvider(create: (context) => GroupeProvider()),
        ChangeNotifierProvider(create: (context) => SeanceProvider()), // Ajouter ici
      ],
      child: MaterialApp(
        title: 'Fédération Judo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(),
      ),
    );
  }
}