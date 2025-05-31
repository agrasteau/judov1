import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/groupe.dart';
import '../providers/groupe_provider.dart';
import 'groupe_form_page.dart';

class GroupeListPage extends StatefulWidget {
  const GroupeListPage({super.key});

  @override
  State<GroupeListPage> createState() => _GroupeListPageState();
}

class _GroupeListPageState extends State<GroupeListPage> {
  @override
  void initState() {
    super.initState();
    // Rafraîchir les groupes au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupeProvider>(context, listen: false).fetchGroupes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupeFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<GroupeProvider>(
        builder: (context, groupeProvider, child) {
          if (groupeProvider.groupes.isEmpty) {
            return const Center(
              child: Text('Aucun groupe enregistré. Cliquez sur le "+" pour en ajouter un.'),
            );
          }
          return ListView.builder(
            itemCount: groupeProvider.groupes.length,
            itemBuilder: (context, index) {
              final groupe = groupeProvider.groupes[index];
              final categories = groupe.categoriesAge.join(', ');
              final judokasCount = groupe.judokas?.length ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(groupe.nom),
                  subtitle: Text(
                    'Catégories: $categories\n'
                        'Judokas: $judokasCount',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupeFormPage(groupe: groupe),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, groupe),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Groupe groupe) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer Groupe'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment supprimer le groupe "${groupe.nom}"?'),
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
                Provider.of<GroupeProvider>(context, listen: false).deleteGroupe(groupe.id!);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}