import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

import '../models/judoka.dart';
import '../models/groupe.dart'; // Importer le modèle Groupe

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'judo_federation.db');
    return await openDatabase(
      path,
      version: 1, // Gardez la version à 1 si c'est la première création, sinon incrémentez
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Ajoutez cette méthode pour gérer les mises à jour
    );
  }

  // --- Méthode de création initiale des tables ---
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Judokas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        dateNaissance TEXT,
        genre TEXT,
        grade TEXT,
        datePassageGrade TEXT,
        categoriePoids TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Groupes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        categoriesAge TEXT -- Ex: "Eveils Judo,Pré-Poussins"
      )
    ''');
    await db.execute('''
      CREATE TABLE GroupeJudokas (
        groupe_id INTEGER,
        judoka_id INTEGER,
        PRIMARY KEY (groupe_id, judoka_id),
        FOREIGN KEY (groupe_id) REFERENCES Groupes(id) ON DELETE CASCADE,
        FOREIGN KEY (judoka_id) REFERENCES Judokas(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Méthode de mise à jour de la base de données (si version incrémentée) ---
  // IMPORTANT: Si vous avez déjà exécuté l'application, vous devrez soit
  // - Incrémenter la version (`version: 2`) et implémenter `_onUpgrade`
  // - Désinstaller l'application de l'émulateur/téléphone pour recréer la DB
  //   (Plus simple pour le développement initial)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // Si l'ancienne version était 0 ou inexistante, on recrée tout comme dans onCreate
      await _onCreate(db, newVersion);
    }
    // Ajoutez des migrations ici si vous avez besoin de changer le schéma de la DB plus tard
    // Exemple: if (oldVersion < 2) { await db.execute("ALTER TABLE Judokas ADD COLUMN newColumn TEXT"); }
  }


  // --- Opérations CRUD pour les Judokas (déjà présentes) ---
  Future<int> insertJudoka(Judoka judoka) async {
    Database db = await database;
    return await db.insert('Judokas', judoka.toMap());
  }

  Future<List<Judoka>> getJudokas() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Judokas');
    return List.generate(maps.length, (i) {
      return Judoka.fromMap(maps[i]);
    });
  }

  Future<int> updateJudoka(Judoka judoka) async {
    Database db = await database;
    return await db.update(
      'Judokas',
      judoka.toMap(),
      where: 'id = ?',
      whereArgs: [judoka.id],
    );
  }

  Future<int> deleteJudoka(int id) async {
    Database db = await database;
    return await db.delete(
      'Judokas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NOUVELLES Opérations CRUD pour les Groupes ---

  Future<int> insertGroupe(Groupe groupe) async {
    Database db = await database;
    return await db.insert('Groupes', groupe.toMap());
  }

  // Récupérer un groupe avec ses judokas associés
  Future<Groupe?> getGroupeById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> groupMaps = await db.query(
      'Groupes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (groupMaps.isEmpty) return null;

    Groupe groupe = Groupe.fromMap(groupMaps.first);

    // Récupérer les judokas associés à ce groupe
    List<Map<String, dynamic>> judokaMaps = await db.rawQuery('''
      SELECT J.* FROM Judokas J
      INNER JOIN GroupeJudokas GJ ON J.id = GJ.judoka_id
      WHERE GJ.groupe_id = ?
    ''', [id]);

    groupe.judokas = List.generate(judokaMaps.length, (i) {
      return Judoka.fromMap(judokaMaps[i]);
    });

    return groupe;
  }

  Future<List<Groupe>> getGroupes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Groupes');
    List<Groupe> groupes = [];

    for (var map in maps) {
      Groupe groupe = Groupe.fromMap(map);
      // Récupérer les judokas pour chaque groupe
      List<Map<String, dynamic>> judokaMaps = await db.rawQuery('''
        SELECT J.* FROM Judokas J
        INNER JOIN GroupeJudokas GJ ON J.id = GJ.judoka_id
        WHERE GJ.groupe_id = ?
      ''', [groupe.id]);
      groupe.judokas = List.generate(judokaMaps.length, (i) {
        return Judoka.fromMap(judokaMaps[i]);
      });
      groupes.add(groupe);
    }
    return groupes;
  }

  Future<int> updateGroupe(Groupe groupe) async {
    Database db = await database;
    return await db.update(
      'Groupes',
      groupe.toMap(),
      where: 'id = ?',
      whereArgs: [groupe.id],
    );
  }

  Future<int> deleteGroupe(int id) async {
    Database db = await database;
    // La suppression en cascade est gérée par la clé étrangère dans GroupeJudokas
    return await db.delete(
      'Groupes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NOUVELLES Opérations pour la table de liaison GroupeJudokas ---

  Future<void> addJudokasToGroup(int groupeId, List<int> judokaIds) async {
    Database db = await database;
    Batch batch = db.batch();
    for (int judokaId in judokaIds) {
      batch.insert('GroupeJudokas', {'groupe_id': groupeId, 'judoka_id': judokaId});
    }
    await batch.commit(noResult: true);
  }

  Future<void> removeJudokasFromGroup(int groupeId, List<int> judokaIds) async {
    Database db = await database;
    Batch batch = db.batch();
    for (int judokaId in judokaIds) {
      batch.delete(
        'GroupeJudokas',
        where: 'groupe_id = ? AND judoka_id = ?',
        whereArgs: [groupeId, judokaId],
      );
    }
    await batch.commit(noResult: true);
  }

  // Supprime toutes les liaisons pour un groupe donné (utilisé avant la mise à jour)
  Future<void> deleteAllJudokasFromGroup(int groupeId) async {
    Database db = await database;
    await db.delete(
      'GroupeJudokas',
      where: 'groupe_id = ?',
      whereArgs: [groupeId],
    );
  }

  // Récupérer les IDs des judokas associés à un groupe
  Future<List<int>> getJudokaIdsForGroup(int groupeId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'GroupeJudokas',
      columns: ['judoka_id'],
      where: 'groupe_id = ?',
      whereArgs: [groupeId],
    );
    return List.generate(maps.length, (i) => maps[i]['judoka_id'] as int);
  }
}