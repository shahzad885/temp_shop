// lib/widgets/hero_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temp_shop/app_theme.dart';
import 'package:temp_shop/screenshot_item.dart';
import 'package:temp_shop/screenshot_providers.dart';
import 'quick_options_sheet.dart';

class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroScreenshotProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    if (hero == null) return _EmptyHero(height: screenHeight * 0.45);

    return GestureDetector(
      onLongPress: () => showQuickOptionsSheet(context, hero),
      onTap: () => showQuickOptionsSheet(context, hero),
      child: SizedBox(
        height: screenHeight * 0.45,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            Image.file(
              File(hero.filePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: AppColors.greyDark),
            ),

            // Top gradient (for status bar readability)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom gradient fade into background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withOpacity(0.3),
                      AppColors.background,
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _HeroActions(item: hero),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActions extends ConsumerWidget {
  final ScreenshotItem item;
  const _HeroActions({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Save / Vault
          Expanded(
            child: _ActionButton(
              icon: item.isVault ? Icons.lock : Icons.bookmark_border,
              label: item.isVault ? 'Saved' : 'Save',
              onTap: () {
                if (item.isVault) {
                  ref
                      .read(screenshotProvider.notifier)
                      .removeFromVault(item.id);
                } else {
                  ref.read(screenshotProvider.notifier).moveToVault(item.id);
                }
              },
              isSecondary: true,
            ),
          ),
          const SizedBox(width: 10),

          // Timer / Set Expiry
          Expanded(
            child: _ActionButton(
              icon: Icons.timer,
              label: item.expiryLabel,
              onTap: () => showQuickOptionsSheet(context, item),
              isSecondary: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white.withOpacity(0.15) : AppColors.red,
          borderRadius: BorderRadius.circular(6),
          border: isSecondary
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  final double height;
  const _EmptyHero({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.screenshot_monitor_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No screenshots yet',
              style: TextStyle(color: AppColors.grey, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Screenshots will appear here automatically',
              style: TextStyle(color: AppColors.greyDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
