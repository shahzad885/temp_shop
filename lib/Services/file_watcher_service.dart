import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../Widgets/screenshot_item.dart';
import '../Providers/screenshot_providers.dart';
import 'overlay_service.dart';

class FileWatcherService {
  Timer? _pollTimer;
  final Ref _ref;
  final Set<String> _knownFiles = {};

  static const _possibleDirs = [
    '/storage/emulated/0/Pictures/Screenshots',
    '/storage/emulated/0/DCIM/Screenshots',
    '/storage/emulated/0/Screenshots',
    '/sdcard/Pictures/Screenshots',
    '/sdcard/DCIM/Screenshots',
  ];

  FileWatcherService(this._ref);

  String? _resolveScreenshotDir() {
    for (final path in _possibleDirs) {
      if (Directory(path).existsSync()) return path;
    }
    return null;
  }

  void start() {
    final dir = _resolveScreenshotDir();
    if (dir == null) {
      Timer.periodic(const Duration(seconds: 10), (timer) {
        final found = _resolveScreenshotDir();
        if (found != null) {
          timer.cancel();
          _initKnownFiles(found);
          _startPolling(found);
        }
      });
      return;
    }
    _initKnownFiles(dir);
    _startPolling(dir);
  }

  void _initKnownFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    _knownFiles.addAll(dir.listSync().whereType<File>().map((f) => f.path));

    final box = _ref.read(hiveBoxProvider);
    for (final item in box.values) {
      _knownFiles.add(item.filePath);
    }
  }

  void _startPolling(String dirPath) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkForNewFiles(dirPath),
    );
  }

  Future<void> _checkForNewFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    final currentFiles = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .toSet();
    final newFiles = currentFiles.difference(_knownFiles);

    for (final path in newFiles) {
      if (_isImageFile(path)) await _onNewScreenshot(path);
    }

    _knownFiles.addAll(currentFiles);
  }

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.webp'].contains(ext);
  }

  Future<void> _onNewScreenshot(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final file = File(filePath);
    if (!file.existsSync()) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = ScreenshotItem(
      id: id,
      filePath: filePath,
      creationDate: DateTime.now(),
      expiryDate: null,
      autoDelete: false,
      categoryName: 'pending',
    );
    await _ref.read(screenshotProvider.notifier).addScreenshot(item);

    await _ref.read(overlayServiceProvider).showOverlay(id);
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}

final fileWatcherProvider = Provider<FileWatcherService>((ref) {
  final service = FileWatcherService(ref);
  ref.onDispose(service.stop);
  return service;
});
