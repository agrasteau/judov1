class Seance {
  int? id;
  int professeurId; // ID du judoka qui est le professeur
  int groupeId; // ID du groupe de judokas
  String description;
  DateTime dateHeure;

  Seance({
    this.id,
    required this.professeurId,
    required this.groupeId,
    required this.description,
    required this.dateHeure,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'professeurId': professeurId,
      'groupeId': groupeId,
      'description': description,
      'dateHeure': dateHeure.toIso8601String(), // Stocker la date et l'heure au format ISO8601
    };
  }

  factory Seance.fromMap(Map<String, dynamic> map) {
    return Seance(
      id: map['id'],
      professeurId: map['professeurId'],
      groupeId: map['groupeId'],
      description: map['description'],
      dateHeure: DateTime.parse(map['dateHeure']), // Convertir la chaîne ISO8601 en DateTime
    );
  }
}