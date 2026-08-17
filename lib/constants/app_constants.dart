/// Constantes métier / UI partagées — C.S. Les Moineaux.
abstract final class AppConstants {
  static const String appName = 'Complexe Scolaire Les Moineaux';
  static const String appTagline = 'Fondé en 2016';
  static const String schoolMotto = 'Fondé en 2016';
  static const String welcomeSubtitle = 'Bienvenue au Complexe Scolaire Les Moineaux';
  static const String brandFallback = 'CS';

  /// Texte présentation (écran À propos).
  static const String schoolPresentation =
      "Le Complexe Scolaire Les Moineaux, fondé en 2016, est un "
      'établissement scolaire privé dédié à la formation intégrale des '
      "élèves dans un environnement propice à l'apprentissage, à la "
      "discipline et à l'épanouissement.";

  /// Options organisées (fiche identification établissement).
  static const List<String> schoolOptions = [
    'Mathématique-Physique',
    'Chimie-Biologie',
    'Littéraire (ex-Latin-Philo)',
    'Pédagogie générale',
    'Sciences sociales',
    'Électricité',
    'Mécanique générale ou automobile',
    'Commerciale et administrative',
    'Agriculture générale / vétérinaire',
    'Nutrition / coupe et couture',
  ];

  static const String schoolCity = '';
  static const String schoolAddress = '';
  static const String schoolBp = '';
  static const String schoolCode = '';
  static const String schoolRegime = 'Privé';
  static const String schoolPhonePrimary = '';
  static const String schoolPhoneSecondary = '';
  static const String schoolPhone = '';
  static const String schoolHours = 'Lun – Ven · Avant et Après-midi';

  static const String logoAsset = 'assets/branding/logo.png';

  static const double radiusLarge = 16;
  static const double radiusMedium = 12;
  static const double radiusSmall = 8;
  static const double radiusButton = 8;

  static const double pagePadding = 16;
  static const double sectionGap = 20;
}
