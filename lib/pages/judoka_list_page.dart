import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/judoka.dart';
import '../providers/judoka_provider.dart';
import 'judoka_form_page.dart';

class JudokaListPage extends StatefulWidget {
  const JudokaListPage({super.key});

  @override
  State<JudokaListPage> createState() => _JudokaListPageState();
}

class _JudokaListPageState extends State<JudokaListPage> {
  @override
  void initState() {
    super.initState();
    // Recharger les judokas au cas où il y ait eu des ajouts/modifications sur une autre page
    // Ou si l'app vient d'être lancée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JudokaProvider>(context, listen: false).fetchJudokas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Judokas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JudokaFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<JudokaProvider>(
        builder: (context, judokaProvider, child) {
          if (judokaProvider.judokas.isEmpty) {
            return const Center(
              child: Text('Aucun judoka enregistré. Cliquez sur le "+" pour en ajouter un.'),
            );
          }
          return ListView.builder(
            itemCount: judokaProvider.judokas.length,
            itemBuilder: (context, index) {
              final judoka = judokaProvider.judokas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('${judoka.prenom} ${judoka.nom}'),
                  subtitle: Text('Grade: ${judoka.grade ?? 'N/A'}'),
                  onTap: () {
                    // Naviguer vers la page de modification avec les données du judoka
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JudokaFormPage(judoka: judoka),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, judoka),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Judoka judoka) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer Judoka'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment supprimer ${judoka.prenom} ${judoka.nom}?'),
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
                Provider.of<JudokaProvider>(context, listen: false).deleteJudoka(judoka.id!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}