import 'package:hive/hive.dart';

class ScreenshotItem extends HiveObject {
  String id;
  String filePath;
  DateTime creationDate;
  DateTime? expiryDate;
  bool autoDelete;
  String categoryName;
  bool isVault;
  String? detectedText;

  ScreenshotItem({
    required this.id,
    required this.filePath,
    required this.creationDate,
    this.expiryDate,
    this.autoDelete = true,
    this.categoryName = 'pending',
    this.isVault = false,
    this.detectedText,
  });

  Duration? get timeRemaining {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now());
  }

  String get expiryLabel {
    final rem = timeRemaining;
    if (rem == null) return 'No expiry';
    if (rem.isNegative) return 'Expired';
    if (rem.inMinutes < 60) return '${rem.inMinutes}m left';
    if (rem.inHours < 24) return '${rem.inHours}h left';
    return '${rem.inDays}d left';
  }
}

// Manual Hive TypeAdapter - no code generation

class ScreenshotItemAdapter extends TypeAdapter<ScreenshotItem> {
  @override
  final int typeId = 0;

  @override
  ScreenshotItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return ScreenshotItem(
      id: fields[0] as String,
      filePath: fields[1] as String,
      creationDate: DateTime.fromMillisecondsSinceEpoch(fields[2] as int),
      expiryDate: fields[3] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[3] as int)
          : null,
      autoDelete: fields[4] as bool? ?? true,
      categoryName: fields[5] as String? ?? 'pending',
      isVault: fields[6] as bool? ?? false,
      detectedText: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenshotItem obj) {
    writer.writeByte(8);

    writer.writeByte(0);
    writer.write(obj.id);

    writer.writeByte(1);
    writer.write(obj.filePath);

    writer.writeByte(2);
    writer.write(obj.creationDate.millisecondsSinceEpoch);

    writer.writeByte(3);
    writer.write(obj.expiryDate?.millisecondsSinceEpoch);

    writer.writeByte(4);
    writer.write(obj.autoDelete);

    writer.writeByte(5);
    writer.write(obj.categoryName);

    writer.writeByte(6);
    writer.write(obj.isVault);

    writer.writeByte(7);
    writer.write(obj.detectedText);
  }
}
