import '../models/notification_models.dart';
import '../services/auth_service.dart';
import '../services/notifications_service.dart';

class NotificationsRepository {
  NotificationsRepository({
    required NotificationsService notificationsService,
    required AuthService authService,
  })  : _notifications = notificationsService,
        _auth = authService;

  final NotificationsService _notifications;
  final AuthService _auth;

  Future<ParentNotificationsResult> load() async {
    final parent = await _auth.readParentSession();
    final guardianId = parent?.guardianPublicId ?? '';
    return _notifications.fetchNotifications(guardianPublicId: guardianId);
  }
}
