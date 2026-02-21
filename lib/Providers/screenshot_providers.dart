import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:temp_shop/Widgets/screenshot_item.dart';

final hiveBoxProvider = Provider<Box<ScreenshotItem>>((ref) {
  return Hive.box<ScreenshotItem>('screenshots');
});

class ScreenshotNotifier extends StateNotifier<List<ScreenshotItem>> {
  final Box<ScreenshotItem> _box;

  ScreenshotNotifier(this._box) : super([]) {
    _loadFromHive();
    _box.listenable().addListener(_loadFromHive);
  }

  void _loadFromHive() {
    final items = _box.values.toList()
      ..sort((a, b) => b.creationDate.compareTo(a.creationDate));
    state = items;
  }

  Future<void> addScreenshot(ScreenshotItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> deleteScreenshot(String id) async {
    final item = _box.get(id);
    if (item != null) {
      final file = File(item.filePath);
      if (await file.exists()) await file.delete();
      await _box.delete(id);
    }
  }

  Future<void> updateExpiry(String id, Duration? duration) async {
    final item = _box.get(id);
    if (item == null) return;
    item.expiryDate = duration != null ? DateTime.now().add(duration) : null;
    item.autoDelete = duration != null;
    await item.save();
    _loadFromHive();
  }

  Future<void> moveToVault(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isVault = true;
    item.expiryDate = null;
    item.autoDelete = false;
    await item.save();
    _loadFromHive();
  }

  Future<void> removeFromVault(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isVault = false;
    await item.save();
    _loadFromHive();
  }

  /// Force reload from Hive — call when returning from background
  void reloadFromHive() => _loadFromHive();

  /// Runs on startup - deletes all expired items
  Future<void> runAutoDeletePass() async {
    final expired = state.where((item) {
      if (!item.autoDelete || item.isVault) return false;
      if (item.expiryDate == null) return false;
      return item.expiryDate!.isBefore(DateTime.now());
    }).toList();

    for (final item in expired) {
      await deleteScreenshot(item.id);
    }
  }

  @override
  void dispose() {
    _box.listenable().removeListener(_loadFromHive);
    super.dispose();
  }
}

final screenshotProvider =
    StateNotifierProvider<ScreenshotNotifier, List<ScreenshotItem>>((ref) {
      final box = ref.watch(hiveBoxProvider);
      return ScreenshotNotifier(box);
    });

final heroScreenshotProvider = Provider<ScreenshotItem?>((ref) {
  final all = ref.watch(screenshotProvider);
  return all.isNotEmpty ? all.first : null;
});

final expiringSoonProvider = Provider<List<ScreenshotItem>>((ref) {
  final all = ref.watch(screenshotProvider);
  return all.where((item) {
    if (item.isVault) return false;
    final rem = item.timeRemaining;
    if (rem == null) return false;
    return !rem.isNegative && rem.inHours < 1;
  }).toList();
});

final otpScreenshotsProvider = Provider<List<ScreenshotItem>>((ref) {
  final all = ref.watch(screenshotProvider);
  return all.where((item) => item.categoryName == 'otp').toList();
});

final vaultScreenshotsProvider = Provider<List<ScreenshotItem>>((ref) {
  final all = ref.watch(screenshotProvider);
  return all.where((item) => item.isVault).toList();
});

const expiryOptions = <String, Duration?>{
  'Keep Forever': null,
  '5 Minutes': Duration(minutes: 5),
  '30 Minutes': Duration(minutes: 30),
  '1 Hour': Duration(hours: 1),
  '3 Hours': Duration(hours: 3),
  '24 Hours': Duration(hours: 24),
  '7 Days': Duration(days: 7),
};
