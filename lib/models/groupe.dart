import 'judoka.dart';

class Groupe {
  int? id;
  String nom;
  List<String> categoriesAge; // Les catégories d'âge associées à ce groupe
  List<Judoka>? judokas;     // Liste des judokas appartenant à ce groupe (optionnel, pour l'affichage)

  Groupe({
    this.id,
    required this.nom,
    required this.categoriesAge,
    this.judokas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'categoriesAge': categoriesAge.join(','), // Stocker les catégories comme une chaîne séparée par des virgules
    };
  }

  factory Groupe.fromMap(Map<String, dynamic> map) {
    return Groupe(
      id: map['id'],
      nom: map['nom'],
      categoriesAge: (map['categoriesAge'] as String)
          .split(',')
          .where((s) => s.isNotEmpty) // Filtrer les chaînes vides au cas où
          .toList(),
    );
  }
}