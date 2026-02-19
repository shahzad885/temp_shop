// lib/overlay_service.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screenshot_providers.dart';

class OverlayService {
  static const _overlayChannel = MethodChannel('com.example.temp_shop/overlay');
  static const _expiryChannel  = MethodChannel('com.example.temp_shop/expiry');

  late ProviderContainer _container;

  Future<void> init(ProviderContainer container) async {
    _container = container;

    // Listen for expiry selections coming from the native overlay buttons
    _expiryChannel.setMethodCallHandler((call) async {
      if (call.method == 'onExpirySelected') {
        final screenshotId   = call.arguments['screenshotId'] as String;
        final durationMins   = call.arguments['durationMinutes'] as int;

        Duration? duration;
        if (durationMins > 0) {
          duration = Duration(minutes: durationMins);
        }
        // -1 means "Keep forever" → duration stays null

        await _container
            .read(screenshotProvider.notifier)
            .updateExpiry(screenshotId, duration);
      }
    });
  }

  Future<bool> hasOverlayPermission() async {
    return await _overlayChannel.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _overlayChannel.invokeMethod('requestOverlayPermission');
  }

  /// Call this when a new screenshot is detected — shows the floating bubble
  Future<void> showOverlay(String screenshotId) async {
    final hasPermission = await hasOverlayPermission();
    if (!hasPermission) {
      await requestOverlayPermission();
      return;
    }
    await _overlayChannel.invokeMethod('showOverlay', {
      'screenshotId': screenshotId,
    });
  }
}

final overlayServiceProvider = Provider<OverlayService>((ref) {
  return OverlayService();
});
