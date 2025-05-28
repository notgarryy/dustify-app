import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInit => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings('splash');

    const initSettings = InitializationSettings(android: initSettingsAndroid);

    await notificationsPlugin.initialize(initSettings);
  }

  NotificationDetails notifDetails({bool silent = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'alert',
        'Alert',
        channelDescription: 'Alert for PM25 and PM10 Channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'splash',
        playSound: !silent, // No sound if silent
        enableVibration: !silent, // No vibration if silent
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final doNotDisturb = prefs.getBool('doNotDisturb') ?? false;

    if (!notificationsEnabled) return;

    return notificationsPlugin.show(
      id,
      title,
      body,
      notifDetails(silent: doNotDisturb), // Use silent mode if DND is active
    );
  }
}
