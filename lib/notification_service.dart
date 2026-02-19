// lib/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screenshot_item.dart';
import 'screenshot_providers.dart';

const _channelId = 'tempshot_expiry';
const _channelName = 'TempShot Expiry';

const _action5m = 'set_5m';
const _action30m = 'set_30m';
const _action1h = 'set_1h';
const _action24h = 'set_24h';
const _actionKeep = 'set_keep';

final FlutterLocalNotificationsPlugin globalNotifPlugin =
    FlutterLocalNotificationsPlugin();

// ─── MUST be top-level (not inside a class) for background isolate ───────────
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) async {
  // Re-init Hive in the background isolate — Flutter engine may not be running
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ScreenshotItemAdapter());
  }
  final box = await Hive.openBox<ScreenshotItem>('screenshots');

  final id = response.payload;
  final action = response.actionId;
  if (id == null || action == null) return;

  final item = box.get(id);
  if (item == null) return;

  Duration? duration;
  switch (action) {
    case _action5m:
      duration = const Duration(minutes: 5);
      break;
    case _action30m:
      duration = const Duration(minutes: 30);
      break;
    case _action1h:
      duration = const Duration(hours: 1);
      break;
    case _action24h:
      duration = const Duration(hours: 24);
      break;
    case _actionKeep:
      duration = null;
      break;
    default:
      return;
  }

  // Write directly to Hive — no provider needed in background
  item.expiryDate = duration != null ? DateTime.now().add(duration) : null;
  item.autoDelete = duration != null;
  await item.save();
}

// ─── Service class ────────────────────────────────────────────────────────────
class NotificationService {
  late ProviderContainer _container;

  Future<void> init(ProviderContainer container) async {
    _container = container;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await globalNotifPlugin.initialize(
      const InitializationSettings(android: androidInit),
      // Foreground taps (app open)
      onDidReceiveNotificationResponse: _onForegroundAction,
      // Background taps (app closed) — must be top-level function
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    await globalNotifPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Choose how long to keep new screenshots',
            importance: Importance.high,
            playSound: true,
          ),
        );
  }

  Future<void> showExpiryPicker({
    required String screenshotId,
    required String filePath,
  }) async {
    final notifId = screenshotId.hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Choose how long to keep this screenshot',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          _action5m,
          '5 min',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _action30m,
          '30 min',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _action1h,
          '1 hr',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _action24h,
          '24 hrs',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _actionKeep,
          'Keep ∞',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    await globalNotifPlugin.show(
      notifId,
      '📸 New Screenshot',
      'How long should this stay on your phone?',
      const NotificationDetails(android: androidDetails),
      payload: screenshotId,
    );
  }

  // Handles action taps when app is in foreground/background (not killed)
  void _onForegroundAction(NotificationResponse response) {
    final id = response.payload;
    final action = response.actionId;
    if (id == null || action == null) return;

    Duration? duration;
    switch (action) {
      case _action5m:
        duration = const Duration(minutes: 5);
        break;
      case _action30m:
        duration = const Duration(minutes: 30);
        break;
      case _action1h:
        duration = const Duration(hours: 1);
        break;
      case _action24h:
        duration = const Duration(hours: 24);
        break;
      case _actionKeep:
        duration = null;
        break;
      default:
        return;
    }

    _container.read(screenshotProvider.notifier).updateExpiry(id, duration);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
