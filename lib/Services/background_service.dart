import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'notification_service.dart';
import '../Widgets/screenshot_item.dart';

const _possibleDirs = [
  '/storage/emulated/0/Pictures/Screenshots',
  '/storage/emulated/0/DCIM/Screenshots',
  '/storage/emulated/0/Screenshots',
  '/sdcard/Pictures/Screenshots',
  '/sdcard/DCIM/Screenshots',
];

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: true,
      isForegroundMode: false,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
  await service.startService();
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ScreenshotItemAdapter());
  }
  final box = await Hive.openBox<ScreenshotItem>('screenshots');

  // Init notification plugin
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await globalNotifPlugin.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
  );
  await globalNotifPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'tempshot_expiry',
          'TempShot Expiry',
          description: 'Choose how long to keep new screenshots',
          importance: Importance.high,
        ),
      );

  // This prevents sending notifications for screenshots that existed
  // before the app was installed, or that were already tracked.
  final Set<String> knownFiles = {};

  // 1. All files currently on disk → mark as "already seen"
  final existingDir = _resolveDir();
  if (existingDir != null) {
    Directory(
      existingDir,
    ).listSync().whereType<File>().forEach((f) => knownFiles.add(f.path));
  }

  // 2. All paths already in Hive → also mark as seen (app reinstall safety)
  for (final item in box.values) {
    knownFiles.add(item.filePath);
  }

  Timer.periodic(const Duration(seconds: 5), (_) async {
    await _runAutoDelete(box);
    await _checkForNewFiles(box, knownFiles);
  });
}

Future<void> _checkForNewFiles(
  Box<ScreenshotItem> box,
  Set<String> knownFiles,
) async {
  final dirPath = _resolveDir();
  if (dirPath == null) return;

  final dir = Directory(dirPath);
  if (!dir.existsSync()) return;

  final current = dir.listSync().whereType<File>().map((f) => f.path).toSet();
  final newFiles = current.difference(knownFiles);

  for (final path in newFiles) {
    final ext = p.extension(path).toLowerCase();
    if (!['.png', '.jpg', '.jpeg', '.webp'].contains(ext)) continue;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!File(path).existsSync()) continue;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = ScreenshotItem(
      id: id,
      filePath: path,
      creationDate: DateTime.now(),
      expiryDate: null,
      autoDelete: false,
      categoryName: 'pending',
    );
    await box.put(id, item);

    await _showExpiryNotification(id);
  }

  knownFiles.addAll(current);
}

Future<void> _showExpiryNotification(String screenshotId) async {
  final notifId = screenshotId.hashCode.abs() % 100000;

  const androidDetails = AndroidNotificationDetails(
    'tempshot_expiry',
    'TempShot Expiry',
    channelDescription: 'Choose how long to keep this screenshot',
    importance: Importance.high,
    priority: Priority.high,
    autoCancel: true,
    fullScreenIntent: false,
    actions: [
      AndroidNotificationAction(
        'set_5m',
        '5 min',
        cancelNotification: true,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        'set_30m',
        '30 min',
        cancelNotification: true,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        'set_1h',
        '1 hr',
        cancelNotification: true,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        'set_24h',
        '24 hrs',
        cancelNotification: true,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        'set_keep',
        'Keep ∞',
        cancelNotification: true,
        showsUserInterface: false,
      ),
    ],
  );

  await globalNotifPlugin.show(
    notifId,
    '📸 Set expiry for new screenshot',
    '5 min  •  30 min  •  1 hr  •  24 hrs  •  Keep',
    const NotificationDetails(android: androidDetails),
    payload: screenshotId,
  );
}

Future<void> _runAutoDelete(Box<ScreenshotItem> box) async {
  final now = DateTime.now();
  final toDelete = box.values.where((item) {
    if (!item.autoDelete || item.isVault) return false;
    if (item.expiryDate == null) return false;
    return item.expiryDate!.isBefore(now);
  }).toList();

  for (final item in toDelete) {
    final file = File(item.filePath);
    if (file.existsSync()) await file.delete();
    await box.delete(item.id);
  }
}

String? _resolveDir() {
  for (final path in _possibleDirs) {
    if (Directory(path).existsSync()) return path;
  }
  return null;
}
