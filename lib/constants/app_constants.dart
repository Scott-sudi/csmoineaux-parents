/// Constantes métier / UI partagées.
abstract final class AppConstants {
  static const String appName = 'Institut Kalunga';
  static const String appTagline = 'La Source du Savoir';
  /// Slogan maquette À propos (= tagline école).
  static const String schoolMotto = 'La Source du Savoir';
  static const String welcomeSubtitle = 'Bienvenue à Institut Kalunga';

  /// Texte présentation (maquette À propos).
  static const String schoolPresentation =
      "L'Institut Kalunga est un établissement scolaire privé dédié à la "
      'formation intégrale des élèves dans un environnement propice à '
      "l'apprentissage, à la discipline et à l'épanouissement.";

  /// Options organisées (fiche identification établissement).
  static const List<String> schoolOptions = [
    'Scientifique option : science',
    'Pédagogie générale',
    'Commerciale & gestion',
    'Mécanique générale',
    'Electricité',
  ];

  /// Coordonnées réelles — fiche identification Institut Kalunga.
  static const String schoolCity = 'Likasi';
  static const String schoolAddress =
      '609, Avenue Kamanyola, centre-ville, Likasi';
  static const String schoolBp = 'BP 74';
  static const String schoolCode = '71041';
  static const String schoolRegime = 'Privé agréé';
  static const String schoolPhonePrimary = '+243 997 039 898';
  static const String schoolPhoneSecondary = '0840287002';
  static const String schoolPhone =
      '+243 997 039 898 / 0840287002';
  static const String schoolHours = 'Lun – Ven · Avant et Après-midi';

  static const String logoAsset = 'assets/branding/logo.png';

  /// Rayons conformes à la maquette.
  static const double radiusLarge = 16;
  static const double radiusMedium = 12;
  static const double radiusSmall = 8;
  static const double radiusButton = 8;

  static const double pagePadding = 16;
  static const double sectionGap = 20;
}
