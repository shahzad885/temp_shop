// lib/widgets/quick_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temp_shop/app_theme.dart';
import 'dart:io';

import 'package:temp_shop/screenshot_item.dart';
import 'package:temp_shop/screenshot_providers.dart';

void showQuickOptionsSheet(BuildContext context, ScreenshotItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuickOptionsSheet(item: item),
  );
}

class QuickOptionsSheet extends ConsumerWidget {
  final ScreenshotItem item;
  const QuickOptionsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Preview thumbnail
          Container(
            margin: const EdgeInsets.all(16),
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.greyDark,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(item.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.image, color: AppColors.grey),
            ),
          ),

          // Current expiry badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  item.expiryLabel,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (item.isVault)
                  _badge('In Vault', AppColors.amber)
                else
                  _badge('Auto-delete ON', AppColors.red),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.greyDark),

          // Set Expiry
          _sectionLabel('Set Expiry Timer'),
          ...expiryOptions.entries.map(
            (e) => _expiryTile(context, ref, e.key, e.value),
          ),

          const Divider(color: AppColors.greyDark),
          _sectionLabel('Actions'),

          // Vault toggle
          ListTile(
            leading: Icon(
              item.isVault ? Icons.lock_open_outlined : Icons.lock_outline,
              color: AppColors.amber,
            ),
            title: Text(
              item.isVault ? 'Remove from Vault' : 'Move to Vault',
              style: const TextStyle(color: AppColors.white),
            ),
            onTap: () {
              if (item.isVault) {
                ref.read(screenshotProvider.notifier).removeFromVault(item.id);
              } else {
                ref.read(screenshotProvider.notifier).moveToVault(item.id);
              }
              Navigator.pop(context);
            },
          ),

          // Delete Now
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.red),
            title: const Text(
              'Delete Now',
              style: TextStyle(color: AppColors.red),
            ),
            onTap: () {
              ref.read(screenshotProvider.notifier).deleteScreenshot(item.id);
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  Widget _expiryTile(
    BuildContext context,
    WidgetRef ref,
    String label,
    Duration? duration,
  ) {
    final isActive = duration == null
        ? item.expiryDate == null
        : item.expiryDate != null &&
              (item.expiryDate!.difference(DateTime.now()) - duration).abs() <
                  const Duration(minutes: 2);

    return ListTile(
      dense: true,
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActive ? AppColors.red : AppColors.grey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.white : AppColors.greyLight,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () {
        ref.read(screenshotProvider.notifier).updateExpiry(item.id, duration);
        Navigator.pop(context);
      },
    );
  }
}
