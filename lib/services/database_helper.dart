import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

import '../models/judoka.dart';
import '../models/groupe.dart';
import '../models/seance.dart'; // Importer le modèle Séance

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
      version: 2, // Incrémentez la version de la base de données
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

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
        categoriesAge TEXT
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
    await db.execute('''
      CREATE TABLE Seances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        professeurId INTEGER NOT NULL,
        groupeId INTEGER NOT NULL,
        description TEXT NOT NULL,
        dateHeure TEXT NOT NULL,
        FOREIGN KEY (professeurId) REFERENCES Judokas(id),
        FOREIGN KEY (groupeId) REFERENCES Groupes(id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajoute la table Seances si la version est inférieure à 2
      await db.execute('''
        CREATE TABLE Seances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          professeurId INTEGER NOT NULL,
          groupeId INTEGER NOT NULL,
          description TEXT NOT NULL,
          dateHeure TEXT NOT NULL,
          FOREIGN KEY (professeurId) REFERENCES Judokas(id),
          FOREIGN KEY (groupeId) REFERENCES Groupes(id)
        )
      ''');
    }
    // Ajoutez d'autres migrations ici si vous avez besoin de changer le schéma de la DB plus tard
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

  // --- Opérations CRUD pour les Groupes (déjà présentes) ---
  Future<int> insertGroupe(Groupe groupe) async {
    Database db = await database;
    return await db.insert('Groupes', groupe.toMap());
  }

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

  // --- Opérations pour la table de liaison GroupeJudokas (déjà présentes) ---
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

  Future<void> deleteAllJudokasFromGroup(int groupeId) async {
    Database db = await database;
    await db.delete(
      'GroupeJudokas',
      where: 'groupe_id = ?',
      whereArgs: [groupeId],
    );
  }

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

  // --- NOUVELLES Opérations CRUD pour les Séances ---

  Future<int> insertSeance(Seance seance) async {
    Database db = await database;
    return await db.insert('Seances', seance.toMap());
  }

  Future<Seance?> getSeanceById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> seanceMaps = await db.query(
      'Seances',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (seanceMaps.isEmpty) return null;

    return Seance.fromMap(seanceMaps.first);
  }

  Future<List<Seance>> getSeances() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Seances');
    return List.generate(maps.length, (i) {
      return Seance.fromMap(maps[i]);
    });
  }

  Future<int> updateSeance(Seance seance) async {
    Database db = await database;
    return await db.update(
      'Seances',
      seance.toMap(),
      where: 'id = ?',
      whereArgs: [seance.id],
    );
  }

  Future<int> deleteSeance(int id) async {
    Database db = await database;
    return await db.delete(
      'Seances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}