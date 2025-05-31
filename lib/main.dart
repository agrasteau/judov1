import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'providers/judoka_provider.dart';
import 'providers/groupe_provider.dart';
import 'services/database_helper.dart'; // Importer DatabaseHelper

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Utiliser Provider pour fournir une instance de DatabaseHelper
        // C'est une instance unique (singleton), donc on peut utiliser Provider.value ou un simple Provider
        // Pour les singletons, on peut le créer une fois et le fournir
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper(), // Fournit l'instance singleton de DatabaseHelper
          lazy: false, // Initialise la DB au démarrage de l'app
        ),
        ChangeNotifierProvider(create: (context) => JudokaProvider()),
        ChangeNotifierProvider(create: (context) => GroupeProvider()),
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