import 'package:equatable/equatable.dart';

import '../config/api_config.dart';

class CommunicationDetail extends Equatable {
  const CommunicationDetail({
    required this.id,
    required this.title,
    required this.content,
    this.categoryLabel = '',
    this.priorityLabel = '',
    this.publishedLabel = '',
    this.studentName = '',
    this.attachmentUrl,
  });

  final String id;
  final String title;
  final String content;
  final String categoryLabel;
  final String priorityLabel;
  final String publishedLabel;
  final String studentName;
  final String? attachmentUrl;

  factory CommunicationDetail.fromJson(Map<String, dynamic> json) {
    return CommunicationDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      priorityLabel: json['priority_label']?.toString() ?? '',
      publishedLabel: json['published_label']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      attachmentUrl: ApiConfig.resolveMediaUrl(json['attachment_url']?.toString()),
    );
  }

  @override
  List<Object?> get props => [id, title, content];
}

class PaymentReceiptDetail extends Equatable {
  const PaymentReceiptDetail({
    required this.id,
    required this.receiptNumber,
    required this.studentName,
    required this.amountLabel,
    required this.pdfUrl,
    this.paymentDateLabel = '',
    this.matricule = '',
    this.className = '',
    this.schoolYearLabel = '',
    this.amountInWords = '',
    this.remainingLabel = '',
    this.purpose = '',
    this.paymentMethodLabel = '',
    this.recordedBy = '',
  });

  final String id;
  final String receiptNumber;
  final String studentName;
  final String amountLabel;
  final String pdfUrl;
  final String paymentDateLabel;
  final String matricule;
  final String className;
  final String schoolYearLabel;
  final String amountInWords;
  final String remainingLabel;
  final String purpose;
  final String paymentMethodLabel;
  final String recordedBy;

  factory PaymentReceiptDetail.fromJson(Map<String, dynamic> json) {
    return PaymentReceiptDetail(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      amountLabel: json['amount_label']?.toString() ?? '',
      pdfUrl: ApiConfig.resolveMediaUrl(json['pdf_url']?.toString()) ?? '',
      paymentDateLabel: json['payment_date_label']?.toString() ?? '',
      matricule: json['matricule']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      schoolYearLabel: json['school_year_label']?.toString() ?? '',
      amountInWords: json['amount_in_words']?.toString() ?? '',
      remainingLabel: json['remaining_label']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      paymentMethodLabel: json['payment_method_label']?.toString() ?? '',
      recordedBy: json['recorded_by']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, receiptNumber, pdfUrl];
}

class DisciplineDetail extends Equatable {
  const DisciplineDetail({
    required this.id,
    required this.source,
    required this.title,
    required this.content,
    this.studentName = '',
    this.statusLabel = '',
    this.dateLabel = '',
    this.timeLabel = '',
    this.location = '',
    this.reason = '',
    this.severityLabel = '',
    this.categoryLabel = '',
  });

  final String id;
  final String source;
  final String title;
  final String content;
  final String studentName;
  final String statusLabel;
  final String dateLabel;
  final String timeLabel;
  final String location;
  final String reason;
  final String severityLabel;
  final String categoryLabel;

  factory DisciplineDetail.fromJson(Map<String, dynamic> json) {
    return DisciplineDetail(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      dateLabel: (json['summon_date_label'] ?? json['incident_date_label'])
              ?.toString() ??
          '',
      timeLabel: json['summon_time_label']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      severityLabel: json['severity_label']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, source, title];
}
