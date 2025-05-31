import 'package:flutter/material.dart';
import '../models/groupe.dart';
import '../models/judoka.dart'; // Pour potentiellement manipuler des judokas liés
import '../services/database_helper.dart';

class GroupeProvider extends ChangeNotifier {
  List<Groupe> _groupes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Groupe> get groupes => _groupes;

  GroupeProvider() {
    fetchGroupes();
  }

  Future<void> fetchGroupes() async {
    _groupes = await _dbHelper.getGroupes();
    notifyListeners();
  }

  Future<void> addGroupe(Groupe groupe, List<int> selectedJudokaIds) async {
    final int newGroupeId = await _dbHelper.insertGroupe(groupe);
    if (selectedJudokaIds.isNotEmpty) {
      await _dbHelper.addJudokasToGroup(newGroupeId, selectedJudokaIds);
    }
    await fetchGroupes(); // Rafraîchit la liste
  }

  Future<void> updateGroupe(Groupe groupe, List<int> selectedJudokaIds) async {
    await _dbHelper.updateGroupe(groupe);
    await _dbHelper.deleteAllJudokasFromGroup(groupe.id!); // Supprime les anciennes liaisons
    if (selectedJudokaIds.isNotEmpty) {
      await _dbHelper.addJudokasToGroup(groupe.id!, selectedJudokaIds); // Ajoute les nouvelles
    }
    await fetchGroupes(); // Rafraîchit la liste
  }

  Future<void> deleteGroupe(int id) async {
    await _dbHelper.deleteGroupe(id);
    await fetchGroupes(); // Rafraîchit la liste
  }
}