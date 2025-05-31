import 'package:flutter/material.dart';
import '../models/judoka.dart';
import '../services/database_helper.dart';

class JudokaProvider extends ChangeNotifier {
  List<Judoka> _judokas = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Judoka> get judokas => _judokas;

  JudokaProvider() {
    fetchJudokas();
  }

  Future<void> fetchJudokas() async {
    _judokas = await _dbHelper.getJudokas();
    notifyListeners(); // Notifie les listeners (widgets) que les données ont changé
  }

  Future<void> addJudoka(Judoka judoka) async {
    await _dbHelper.insertJudoka(judoka);
    await fetchJudokas(); // Rafraîchit la liste après l'ajout
  }

  Future<void> updateJudoka(Judoka judoka) async {
    await _dbHelper.updateJudoka(judoka);
    await fetchJudokas(); // Rafraîchit la liste après la mise à jour
  }

  Future<void> deleteJudoka(int id) async {
    await _dbHelper.deleteJudoka(id);
    await fetchJudokas(); // Rafraîchit la liste après la suppression
  }
}