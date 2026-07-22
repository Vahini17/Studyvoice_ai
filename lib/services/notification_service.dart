import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  bool _notificationsEnabled = true;
  String _reminderTime = "09:00 AM";

  NotificationService() {
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _reminderTime = prefs.getString('notifications_reminder_time') ?? "09:00 AM";
  }

  bool get isEnabled => _notificationsEnabled;
  String get reminderTime => _reminderTime;

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> setReminderTime(String time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications_reminder_time', time);
  }

  /// Triggers a mock local banner notification (e.g. standard snackbar or overlay in Flutter)
  void showLocalNotification(BuildContext context, String title, String body) {
    if (!_notificationsEnabled) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF6366F1), // Indigo
      ),
    );
  }
}
