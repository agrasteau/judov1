import 'package:intl/intl.dart';

// Définition des catégories d'âge et de leurs années correspondantes
const Map<String, List<int>> JUDO_AGE_CATEGORIES = {
  'Eveils Judo': [2019, 2020], // Années de naissance
  'Pré-Poussins': [2017, 2018],
  'Poussins': [2015, 2016],
  'Benjamins': [2013, 2014],
  'Minimes': [2011, 2012],
  'Cadets': [2008, 2009, 2010],
  'Juniors': [2005, 2006, 2007],
  'Seniors': [2004], // "2004 et avant" pour les seniors, nous le gérons avec l'âge
  'Vétérans': [1994], // "1994 et avant" pour les vétérans, géré avec l'âge
};

// Liste des noms de catégories pour les Dropdowns
const List<String> CATEGORY_NAMES = [
  'Eveils Judo',
  'Pré-Poussins',
  'Poussins',
  'Benjamins',
  'Minimes',
  'Cadets',
  'Juniors',
  'Seniors',
  'Vétérans',
];


// Fonction pour déterminer la catégorie d'âge d'un judoka basé sur sa date de naissance
String? getJudoAgeCategory(String? dateNaissance) {
  if (dateNaissance == null || dateNaissance.isEmpty) {
    return null; // Si pas de date de naissance, pas de catégorie d'âge spécifique
  }

  try {
    final DateTime dob = DateTime.parse(dateNaissance);
    final int birthYear = dob.year;

    for (var category in JUDO_AGE_CATEGORIES.entries) {
      final String categoryName = category.key;
      final List<int> birthYears = category.value;

      // Pour les catégories normales (par tranches d'années)
      if (categoryName != 'Seniors' && categoryName != 'Vétérans') {
        if (birthYears.contains(birthYear)) {
          return categoryName;
        }
      } else if (categoryName == 'Seniors') {
        // Seniors: 2004 et avant
        if (birthYear <= 2004) {
          return categoryName;
        }
      } else if (categoryName == 'Vétérans') {
        // Vétérans: 1994 et avant
        if (birthYear <= 1994) {
          return categoryName;
        }
      }
    }
  } catch (e) {
    print('Erreur lors du calcul de la catégorie d\'âge: $e');
  }

  return null; // Aucune catégorie trouvée
}