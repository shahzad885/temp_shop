import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:temp_shop/Theme/app_theme.dart';
import 'package:temp_shop/Services/background_service.dart';
import 'package:temp_shop/Services/file_watcher_service.dart';
import 'package:temp_shop/Screens/home_screen.dart';
import 'package:temp_shop/Services/notification_service.dart';
import 'package:temp_shop/Services/overlay_service.dart';
import 'package:temp_shop/Widgets/screenshot_item.dart';
import 'package:temp_shop/Providers/screenshot_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ScreenshotItemAdapter());
  await Hive.openBox<ScreenshotItem>('screenshots');

  await initBackgroundService();

  runApp(const ProviderScope(child: TempShotApp()));
}

Future<void> _requestPermissions() async {
  await Permission.photos.request();
  await Permission.storage.request();
  await Permission.notification.request();

  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
    if (!await Permission.manageExternalStorage.isGranted) {
      await openAppSettings();
    }
  }
}

class TempShotApp extends ConsumerStatefulWidget {
  const TempShotApp({super.key});

  @override
  ConsumerState<TempShotApp> createState() => _TempShotAppState();
}

class _TempShotAppState extends ConsumerState<TempShotApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();

      final container = ProviderScope.containerOf(context);

      // Init notification service (fallback for when overlay permission is denied)
      await container.read(notificationServiceProvider).init(container);

      // Init overlay service — listens for native button taps
      await container.read(overlayServiceProvider).init(container);

      // Request overlay permission upfront so it's ready when first screenshot arrives
      final overlay = container.read(overlayServiceProvider);
      if (!await overlay.hasOverlayPermission()) {
        await overlay.requestOverlayPermission();
      }

      await ref.read(screenshotProvider.notifier).runAutoDeletePass();
      ref.read(fileWatcherProvider).start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(screenshotProvider.notifier).reloadFromHive();
      ref.read(fileWatcherProvider).start();
    } else if (state == AppLifecycleState.paused) {
      ref.read(fileWatcherProvider).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempShot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
