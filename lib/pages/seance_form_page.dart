import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour le formatage de la date et de l'heure
import '../models/seance.dart';
import '../models/judoka.dart';
import '../models/groupe.dart';
import '../providers/seance_provider.dart';
import '../providers/judoka_provider.dart';
import '../providers/groupe_provider.dart';

class SeanceFormPage extends StatefulWidget {
  final Seance? seance;

  const SeanceFormPage({super.key, this.seance});

  @override
  State<SeanceFormPage> createState() => _SeanceFormPageState();
}

class _SeanceFormPageState extends State<SeanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _dateHeureController;

  int? _selectedProfesseurId;
  int? _selectedGroupeId;

  List<Judoka> _professeurs = [];
  List<Groupe> _groupes = [];
  List<Judoka> _judokasDuGroupe = []; // Pour l'appel (présence)
  Map<int, bool> _presence = {}; // judokaId -> présent

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.seance?.description ?? '');
    _dateHeureController = TextEditingController(
        text: widget.seance?.dateHeure != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(widget.seance!.dateHeure)
            : '');
    _selectedProfesseurId = widget.seance?.professeurId;
    _selectedGroupeId = widget.seance?.groupeId;

    // Charger les professeurs (ceinture noire ou plus) et les groupes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final judokaProvider = Provider.of<JudokaProvider>(context, listen: false);
      _professeurs = judokaProvider.judokas.where((j) => j.grade != null && (j.grade!.contains('Noir') )).toList();
      _groupes = Provider.of<GroupeProvider>(context, listen: false).groupes;

      // Si on est en édition, charger les judokas du groupe pour l'appel
      if (widget.seance != null) {
        final groupe = _groupes.firstWhere((g) => g.id == widget.seance!.groupeId);
        _judokasDuGroupe = groupe.judokas ?? [];
        for (var judoka in _judokasDuGroupe) {
          _presence[judoka.id!] = true; // Par défaut, tous présents
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateHeureController.dispose();
    super.dispose();
  }

  Future<void> _selectDateHeure(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          final dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateHeureController.text = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
        });
      }
    }
  }

  void _saveSeance() async {
    if (_formKey.currentState!.validate()) {
      final newSeance = Seance(
        id: widget.seance?.id,
        professeurId: _selectedProfesseurId!,
        groupeId: _selectedGroupeId!,
        description: _descriptionController.text,
        dateHeure: DateFormat('dd/MM/yyyy HH:mm').parse(_dateHeureController.text),
      );

      final seanceProvider = Provider.of<SeanceProvider>(context, listen: false);

      if (widget.seance == null) {
        await seanceProvider.addSeance(newSeance);
      } else {
        await seanceProvider.updateSeance(newSeance);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.seance != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Séance' : 'Ajouter Séance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<int>(
                value: _selectedProfesseurId,
                decoration: const InputDecoration(labelText: 'Professeur'),
                items: _professeurs.map((Judoka professeur) {
                  return DropdownMenuItem<int>(
                    value: professeur.id,
                    child: Text('${professeur.prenom} ${professeur.nom} (${professeur.grade})'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedProfesseurId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un professeur' : null,
              ),
              DropdownButtonFormField<int>(
                value: _selectedGroupeId,
                decoration: const InputDecoration(labelText: 'Groupe'),
                items: _groupes.map((Groupe groupe) {
                  return DropdownMenuItem<int>(
                    value: groupe.id,
                    child: Text(groupe.nom),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedGroupeId = newValue;
                    // Mettre à jour la liste des judokas du groupe sélectionné
                    _judokasDuGroupe = _groupes.firstWhere((g) => g.id == newValue).judokas ?? [];
                    // Réinitialiser la présence pour le nouveau groupe
                    _presence.clear();
                    for (var judoka in _judokasDuGroupe) {
                      _presence[judoka.id!] = true; // Par défaut, tous présents
                    }
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un groupe' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateHeureController,
                decoration: InputDecoration(
                  labelText: 'Date et heure',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDateHeure(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une date et une heure';
                  }
                  try {
                    DateFormat('dd/MM/yyyy HH:mm').parse(value);
                    return null;
                  } catch (e) {
                    return 'Format de date et heure invalide';
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_judokasDuGroupe.isNotEmpty) ...[
                const Text('Présence:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                for (var judoka in _judokasDuGroupe)
                  CheckboxListTile(
                    title: Text('${judoka.prenom} ${judoka.nom}'),
                    value: _presence[judoka.id!] ?? true, // Par défaut, tous présents
                    onChanged: (bool? value) {
                      setState(() {
                        _presence[judoka.id!] = value ?? true;
                      });
                    },
                  ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSeance,
                child: Text(isEditing ? 'Mettre à jour la séance' : 'Créer la séance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}