import 'package:flutter/material.dart';
import 'judoka_list_page.dart';
import 'groupe_list_page.dart';
import 'seance_list_page.dart'; // Importer la nouvelle page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fédération Judo'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildOptionButton(
              context,
              'Judokas',
              Icons.person,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JudokaListPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionButton(
              context,
              'Groupes',
              Icons.group,
                  () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupeListPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionButton(
              context,
              'Séances',
              Icons.event,
                  () => Navigator.push( // Modifier ici pour naviguer vers SeanceListPage
                context,
                MaterialPageRoute(builder: (context) => const SeanceListPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 30),
        label: Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}