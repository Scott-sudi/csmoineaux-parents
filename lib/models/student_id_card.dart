import 'package:equatable/equatable.dart';

import '../config/api_config.dart';
import '../constants/app_constants.dart';

/// Carte d'élève (données secrétariat / PNG web).
class StudentIdCard extends Equatable {
  const StudentIdCard({
    required this.cardNumber,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.matricule,
    required this.classe,
    required this.section,
    required this.option,
    required this.annee,
    this.previewUrl,
    this.photoUrl,
    this.qrImageUrl,
    this.schoolName = AppConstants.appName,
    this.schoolSlogan = AppConstants.appTagline,
    this.schoolCode = AppConstants.schoolCode,
    this.schoolCity = AppConstants.schoolCity,
    this.isBlocked = false,
  });

  final String cardNumber;
  final String nom;
  final String postnom;
  final String prenom;
  final String matricule;
  final String classe;
  final String section;
  final String option;
  final String annee;
  final String? previewUrl;
  final String? photoUrl;
  final String? qrImageUrl;
  final String schoolName;
  final String schoolSlogan;
  final String schoolCode;
  final String schoolCity;
  final bool isBlocked;

  factory StudentIdCard.fromJson(Map<String, dynamic> json) {
    return StudentIdCard(
      cardNumber: json['card_number']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      postnom: json['postnom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      matricule: json['matricule']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      option: json['option']?.toString() ?? '',
      annee: json['annee']?.toString() ?? '',
      previewUrl: ApiConfig.resolveMediaUrl(json['preview_url']?.toString()),
      photoUrl: ApiConfig.resolveMediaUrl(json['photo_url']?.toString()),
      qrImageUrl: ApiConfig.resolveMediaUrl(json['qr_image_url']?.toString()),
      schoolName: json['school_name']?.toString() ?? AppConstants.appName,
      schoolSlogan: json['school_slogan']?.toString() ?? AppConstants.appTagline,
      schoolCode: json['school_code']?.toString() ?? AppConstants.schoolCode,
      schoolCity: json['school_city']?.toString() ?? AppConstants.schoolCity,
      isBlocked: json['is_blocked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [cardNumber, matricule, previewUrl];
}
