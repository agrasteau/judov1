import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/groupe.dart';
import '../models/judoka.dart';
import '../providers/groupe_provider.dart';
import '../providers/judoka_provider.dart';
import '../services/database_helper.dart'; // Importez DatabaseHelper
import '../utils/age_calculator.dart';

class GroupeFormPage extends StatefulWidget {
  final Groupe? groupe;

  const GroupeFormPage({super.key, this.groupe});

  @override
  State<GroupeFormPage> createState() => _GroupeFormPageState();
}

class _GroupeFormPageState extends State<GroupeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;

  Set<String> _selectedCategories = {};
  Map<int, bool> _selectedJudokas = {};
  List<Judoka> _filteredJudokas = [];
  List<Judoka> _allJudokas = []; // Liste de tous les judokas

  // Future pour gérer le chargement asynchrone des données initiales
  late Future<void> _loadInitialDataFuture;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.groupe?.nom ?? '');

    if (widget.groupe != null) {
      _selectedCategories = Set<String>.from(widget.groupe!.categoriesAge);
    }

    _loadInitialDataFuture = _loadInitialData(); // Lance le chargement des données
  }

  // Méthode asynchrone pour charger toutes les données nécessaires
  Future<void> _loadInitialData() async {
    // Assurez-vous d'avoir accès au context pour Provider.of
    _allJudokas = Provider.of<JudokaProvider>(context, listen: false).judokas;

    // Initialiser _selectedJudokas pour tous les judokas à false par défaut
    for (var judoka in _allJudokas) {
      _selectedJudokas[judoka.id!] = false;
    }

    // Si c'est un groupe existant (édition), récupérer les judokas déjà associés
    if (widget.groupe != null) {
      // Obtenir l'instance de DatabaseHelper via Provider (attention au listen: false)
      final databaseHelper = Provider.of<DatabaseHelper>(context, listen: false);
      final List<int> currentJudokaIds =
      await databaseHelper.getJudokaIdsForGroup(widget.groupe!.id!);

      // Mettre à jour l'état de sélection pour les judokas déjà dans le groupe
      for (var judokaId in currentJudokaIds) {
        if (_selectedJudokas.containsKey(judokaId)) { // Assurez-vous que le judoka existe dans _allJudokas
          _selectedJudokas[judokaId] = true;
        }
      }
    }

    // Appliquer le filtre après que _allJudokas et _selectedCategories soient prêts
    _applyCategoryFilter();
    // Ne pas appeler setState ici car FutureBuilder gérera la reconstruction
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  void _applyCategoryFilter() {
    // Important: setState est appelé ici pour re-filtrer les judokas
    // après que _selectedCategories ait changé ou après le chargement initial.
    setState(() {
      _filteredJudokas.clear();
      if (_selectedCategories.isEmpty) {
        // Si aucune catégorie n'est sélectionnée, inclure uniquement les judokas sans date de naissance
        _filteredJudokas = _allJudokas
            .where((j) => j.dateNaissance == null || j.dateNaissance!.isEmpty)
            .toList();
      } else {
        for (var judoka in _allJudokas) {
          final String? judokaCategory = getJudoAgeCategory(judoka.dateNaissance);
          if ((judokaCategory != null &&
              _selectedCategories.contains(judokaCategory)) ||
              (judoka.dateNaissance == null || judoka.dateNaissance!.isEmpty)) {
            _filteredJudokas.add(judoka);
          }
        }
      }
      _filteredJudokas.sort((a, b) => (a.nom + a.prenom).compareTo(b.nom + b.prenom));
    });
  }

  void _saveGroupe() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty && !_selectedJudokas.values.any((selected) => selected)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner au moins une catégorie ou un judoka.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newGroupe = Groupe(
        id: widget.groupe?.id,
        nom: _nomController.text,
        categoriesAge: _selectedCategories.toList(),
      );

      final groupeProvider = Provider.of<GroupeProvider>(context, listen: false);

      final List<int> judokasToAssociate = _selectedJudokas.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      if (widget.groupe == null) {
        await groupeProvider.addGroupe(newGroupe, judokasToAssociate);
      } else {
        await groupeProvider.updateGroupe(newGroupe, judokasToAssociate);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.groupe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Groupe' : 'Ajouter Groupe'),
      ),
      body: FutureBuilder<void>(
        future: _loadInitialDataFuture, // Attendre que les données soient chargées
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
          } else {
            // Une fois les données chargées, afficher le formulaire
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(labelText: 'Nom du groupe'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom pour le groupe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Sélectionner les catégories d\'âge:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: CATEGORY_NAMES.length,
                        itemBuilder: (context, index) {
                          final category = CATEGORY_NAMES[index];
                          return CheckboxListTile(
                            title: Text(category),
                            value: _selectedCategories.contains(category),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                                _applyCategoryFilter(); // Re-filtrer les judokas
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sélectionner les judokas (filtrés par catégories):',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      flex: 2,
                      child: _filteredJudokas.isEmpty
                          ? const Center(
                        child: Text(
                            'Aucun judoka correspondant aux catégories sélectionnées ou sans date de naissance.'),
                      )
                          : ListView.builder(
                        itemCount: _filteredJudokas.length,
                        itemBuilder: (context, index) {
                          final judoka = _filteredJudokas[index];
                          final String? judokaCategory =
                          getJudoAgeCategory(judoka.dateNaissance);

                          String subtitleText =
                              'Catégorie: ${judokaCategory ?? 'Non renseigné'}';
                          if (judoka.dateNaissance == null ||
                              judoka.dateNaissance!.isEmpty) {
                            subtitleText = 'Date de naissance non renseignée';
                          }

                          return CheckboxListTile(
                            title: Text('${judoka.prenom} ${judoka.nom}'),
                            subtitle: Text(subtitleText),
                            value: _selectedJudokas[judoka.id!] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                _selectedJudokas[judoka.id!] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveGroupe,
                      child: Text(isEditing ? 'Mettre à jour le groupe' : 'Créer le groupe'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}