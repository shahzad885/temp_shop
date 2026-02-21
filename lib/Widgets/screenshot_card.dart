import 'dart:io';
import 'package:flutter/material.dart';
import 'package:temp_shop/Theme/app_theme.dart';
import 'package:temp_shop/Widgets/screenshot_item.dart';

import 'quick_options_sheet.dart';

class ScreenshotCard extends StatelessWidget {
  final ScreenshotItem item;
  final double width;
  final double height;

  const ScreenshotCard({
    super.key,
    required this.item,
    this.width = 130,
    this.height = 175,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => showQuickOptionsSheet(context, item),
      onTap: () => showQuickOptionsSheet(context, item),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.greyDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(item.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.greyDark,
                child: const Icon(Icons.image, color: AppColors.grey),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            if (item.expiryDate != null)
              Positioned(top: 6, right: 6, child: _ExpiryBadge(item: item)),

            if (item.isVault)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.lock, color: AppColors.amber, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final ScreenshotItem item;
  const _ExpiryBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final rem = item.timeRemaining;
    if (rem == null || rem.isNegative) return const SizedBox.shrink();

    final isUrgent = rem.inMinutes < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.red : Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 10, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 3),
          Text(
            item.expiryLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
