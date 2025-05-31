import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour formater la date et l'heure
import '../models/seance.dart';
import '../providers/seance_provider.dart';
import 'seance_form_page.dart';

class SeanceListPage extends StatefulWidget {
  const SeanceListPage({super.key});

  @override
  State<SeanceListPage> createState() => _SeanceListPageState();
}

class _SeanceListPageState extends State<SeanceListPage> {
  @override
  void initState() {
    super.initState();
    // Rafraîchir les séances au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SeanceProvider>(context, listen: false).fetchSeances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Séances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeanceFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SeanceProvider>(
        builder: (context, seanceProvider, child) {
          if (seanceProvider.seances.isEmpty) {
            return const Center(
              child: Text('Aucune séance enregistrée. Cliquez sur le "+" pour en ajouter une.'),
            );
          }
          return ListView.builder(
            itemCount: seanceProvider.seances.length,
            itemBuilder: (context, index) {
              final seance = seanceProvider.seances[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('Séance du ${DateFormat('dd/MM/yyyy à HH:mm').format(seance.dateHeure)}'),
                  subtitle: Text(seance.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeanceFormPage(seance: seance),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, seance),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Seance seance) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer Séance'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment supprimer la séance du ${DateFormat('dd/MM/yyyy à HH:mm').format(seance.dateHeure)} ?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<SeanceProvider>(context, listen: false).deleteSeance(seance.id!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}