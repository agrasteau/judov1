class Judoka {
  int? id;
  String nom;
  String prenom;
  String? dateNaissance; // Format "AAAA-MM-JJ"
  String? genre;         // "Masculin", "Féminin", "Non spécifié"
  String? grade;
  String? datePassageGrade; // Format "AAAA-MM-JJ"
  String? categoriePoids;

  Judoka({
    this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.genre,
    this.grade,
    this.datePassageGrade,
    this.categoriePoids,
  });

  // Convertir un Judoka en Map pour insertion dans la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance,
      'genre': genre,
      'grade': grade,
      'datePassageGrade': datePassageGrade,
      'categoriePoids': categoriePoids,
    };
  }

  // Créer un Judoka à partir d'une Map (extraite de la base de données)
  factory Judoka.fromMap(Map<String, dynamic> map) {
    return Judoka(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      dateNaissance: map['dateNaissance'],
      genre: map['genre'],
      grade: map['grade'],
      datePassageGrade: map['datePassageGrade'],
      categoriePoids: map['categoriePoids'],
    );
  }
}