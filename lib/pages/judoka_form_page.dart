import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates
import 'package:provider/provider.dart';
import '../models/judoka.dart';
import '../providers/judoka_provider.dart';

class JudokaFormPage extends StatefulWidget {
  final Judoka? judoka; // Si judoka est non null, c'est une édition

  const JudokaFormPage({super.key, this.judoka});

  @override
  State<JudokaFormPage> createState() => _JudokaFormPageState();
}

class _JudokaFormPageState extends State<JudokaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _dateNaissanceController;
  late TextEditingController _datePassageGradeController;

  String? _selectedGenre;
  String? _selectedGrade;
  String? _selectedCategoriePoids;

  final List<String> _genres = ['Masculin', 'Féminin', 'Non spécifié'];
  final List<String> _grades = [
    'Blanc',
    'Jaune',
    'Orange',
    'Vert',
    'Bleu',
    'Marron',
    'Noir 1er Dan',
    'Noir 2ème Dan',
    'Noir 3ème Dan',
    'Noir 4ème Dan',
    'Noir 5ème Dan',
    // ... ajoutez d'autres grades si nécessaire
  ];

  final Map<String, List<String>> _categoriesPoids = {
    'Masculin': [
      '-60 kg',
      '-66 kg',
      '-73 kg',
      '-81 kg',
      '-90 kg',
      '-100 kg',
      '+100 kg'
    ],
    'Féminin': [
      '-48 kg',
      '-52 kg',
      '-57 kg',
      '-63 kg',
      '-70 kg',
      '-78 kg',
      '+78 kg'
    ],
  };

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.judoka?.nom ?? '');
    _prenomController = TextEditingController(text: widget.judoka?.prenom ?? '');
    _dateNaissanceController =
        TextEditingController(text: widget.judoka?.dateNaissance ?? '');
    _datePassageGradeController =
        TextEditingController(text: widget.judoka?.datePassageGrade ?? '');
    _selectedGenre = widget.judoka?.genre;
    _selectedGrade = widget.judoka?.grade;
    _selectedCategoriePoids = widget.judoka?.categoriePoids;

    // Assurez-vous que la catégorie de poids est valide pour le genre sélectionné au démarrage
    _updateCategoriePoidsBasedOnGenre();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _dateNaissanceController.dispose();
    _datePassageGradeController.dispose();
    super.dispose();
  }

  void _saveJudoka() async {
    if (_formKey.currentState!.validate()) {
      final newJudoka = Judoka(
        id: widget.judoka?.id, // ID existant si édition, null si création
        nom: _nomController.text,
        prenom: _prenomController.text,
        dateNaissance: _dateNaissanceController.text.isNotEmpty
            ? _dateNaissanceController.text
            : null,
        genre: _selectedGenre,
        grade: _selectedGrade,
        datePassageGrade: _datePassageGradeController.text.isNotEmpty
            ? _datePassageGradeController.text
            : null,
        categoriePoids: _selectedCategoriePoids,
      );

      final judokaProvider = Provider.of<JudokaProvider>(context, listen: false);

      if (widget.judoka == null) {
        await judokaProvider.addJudoka(newJudoka);
      } else {
        await judokaProvider.updateJudoka(newJudoka);
      }
      Navigator.pop(context); // Retourne à la liste des judokas
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  void _updateCategoriePoidsBasedOnGenre() {
    setState(() {
      if (_selectedGenre == 'Masculin' || _selectedGenre == 'Féminin') {
        // Vérifier si la catégorie de poids actuelle est compatible
        if (_selectedCategoriePoids != null &&
            !_categoriesPoids[_selectedGenre]!
                .contains(_selectedCategoriePoids)) {
          _selectedCategoriePoids = null; // Réinitialiser si incompatible
        }
      } else {
        _selectedCategoriePoids = null; // Si genre non spécifié, réinitialiser
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.judoka != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Judoka' : 'Ajouter Judoka'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prénom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateNaissanceController,
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () =>
                        _selectDate(context, _dateNaissanceController),
                  ),
                ),
                readOnly: true, // Empêche la saisie directe
              ),
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: _genres.map((String genre) {
                  return DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGenre = newValue;
                    _updateCategoriePoidsBasedOnGenre();
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(labelText: 'Grade'),
                items: _grades.map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGrade = newValue;
                  });
                },
              ),
              if (_selectedGrade != null && _selectedGrade!.isNotEmpty)
                TextFormField(
                  controller: _datePassageGradeController,
                  decoration: InputDecoration(
                    labelText: 'Date de passage du dernier grade',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () =>
                          _selectDate(context, _datePassageGradeController),
                    ),
                  ),
                  readOnly: true,
                ),
              DropdownButtonFormField<String>(
                value: _selectedCategoriePoids,
                decoration: const InputDecoration(labelText: 'Catégorie de poids'),
                items: (_selectedGenre != null &&
                    (_selectedGenre == 'Masculin' ||
                        _selectedGenre == 'Féminin'))
                    ? _categoriesPoids[_selectedGenre]!
                    .map((String categorie) {
                  return DropdownMenuItem<String>(
                    value: categorie,
                    child: Text(categorie),
                  );
                }).toList()
                    : [], // Vide si pas de genre ou non spécifié
                onChanged: (_selectedGenre == 'Masculin' ||
                    _selectedGenre == 'Féminin')
                    ? (String? newValue) {
                  setState(() {
                    _selectedCategoriePoids = newValue;
                  });
                }
                    : null, // Désactivé si genre non spécifié
                hint: const Text('Sélectionnez une catégorie'),
                // Griser le champ si le genre n'est pas spécifié ou est "Non spécifié"
                // Pour cela, nous rendons les items et onChanged null.
                // L'UI de DropdownButtonFormField gérera le grisé automatiquement.
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveJudoka,
                child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}