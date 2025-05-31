import 'package:flutter/material.dart';
import '../models/seance.dart';
import '../services/database_helper.dart';

class SeanceProvider extends ChangeNotifier {
  List<Seance> _seances = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Seance> get seances => _seances;

  SeanceProvider() {
    fetchSeances();
  }

  Future<void> fetchSeances() async {
    _seances = await _dbHelper.getSeances();
    notifyListeners();
  }

  Future<void> addSeance(Seance seance) async {
    await _dbHelper.insertSeance(seance);
    await fetchSeances(); // Rafraîchit la liste
  }

  Future<void> updateSeance(Seance seance) async {
    await _dbHelper.updateSeance(seance);
    await fetchSeances(); // Rafraîchit la liste
  }

  Future<void> deleteSeance(int id) async {
    await _dbHelper.deleteSeance(id);
    await fetchSeances(); // Rafraîchit la liste
  }
}