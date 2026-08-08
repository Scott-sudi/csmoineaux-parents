import '../constants/api_endpoints.dart';
import '../core/errors/api_exception.dart';
import '../core/network/api_service.dart';
import '../models/child_module_models.dart';

/// Modules par enfant (présence, discipline, finance) — API Django.
class ChildModulesService {
  ChildModulesService({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<AttendanceListResult> fetchAttendance({
    required String guardianPublicId,
    required String studentId,
    required String kind,
  }) async {
    try {
      final response = await _api.get<AttendanceListResult>(
        ApiEndpoints.childAttendance(studentId),
        queryParameters: {
          'guardian_public_id': guardianPublicId,
          'kind': kind,
        },
        parser: (raw) => AttendanceListResult.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ),
      );
      return response.data ??
          const AttendanceListResult(
            studentName: '',
            kind: 'present',
            days: [],
          );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }

  Future<DisciplineDossier> fetchDiscipline({
    required String guardianPublicId,
    required String studentId,
  }) async {
    try {
      final response = await _api.get<DisciplineDossier>(
        ApiEndpoints.childDiscipline(studentId),
        queryParameters: {'guardian_public_id': guardianPublicId},
        parser: (raw) => DisciplineDossier.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ),
      );
      return response.data ??
          const DisciplineDossier(
            studentName: '',
            incidents: [],
            measures: [],
            summonses: [],
          );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }

  Future<ChildFinanceSituation> fetchFinance({
    required String guardianPublicId,
    required String studentId,
  }) async {
    try {
      final response = await _api.get<ChildFinanceSituation>(
        ApiEndpoints.childFinance(studentId),
        queryParameters: {'guardian_public_id': guardianPublicId},
        parser: (raw) => ChildFinanceSituation.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ),
      );
      return response.data ??
          const ChildFinanceSituation(
            studentName: '',
            amountDueLabel: '0 CDF',
            amountPaidLabel: '0 CDF',
            amountRemainingLabel: '0 CDF',
            tone: 'paid',
            obligations: [],
            payments: [],
          );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }
}
