// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temp_shop/app_theme.dart';
import 'package:temp_shop/hero_section.dart';
import 'package:temp_shop/screenshot_lane.dart';
import 'package:temp_shop/screenshot_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final expiringSoon = ref.watch(expiringSoonProvider);
    final otpItems = ref.watch(otpScreenshotsProvider);
    final vaultItems = ref.watch(vaultScreenshotsProvider);
    final allItems = ref.watch(screenshotProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: CustomScrollView(
          slivers: [
            // Hero section (top 45%)
            const SliverToBoxAdapter(child: HeroSection()),

            // Expiring Soon lane
            SliverToBoxAdapter(
              child: ScreenshotLane(
                title: 'Expiring Soon',
                items: expiringSoon,
                badge: expiringSoon.isNotEmpty ? expiringSoon.length : null,
                onViewAll: expiringSoon.isNotEmpty ? () {} : null,
                accentColor: AppColors.red,
              ),
            ),

            // OTP lane
            SliverToBoxAdapter(
              child: ScreenshotLane(
                title: 'Smart Detected: OTPs',
                items: otpItems,
                badge: otpItems.isNotEmpty ? otpItems.length : null,
                onViewAll: otpItems.isNotEmpty ? () {} : null,
                accentColor: AppColors.amber,
              ),
            ),

            // The Vault lane
            SliverToBoxAdapter(
              child: ScreenshotLane(
                title: 'The Vault',
                items: vaultItems,
                badge: vaultItems.isNotEmpty ? vaultItems.length : null,
                onViewAll: vaultItems.isNotEmpty ? () {} : null,
                accentColor: AppColors.amber,
              ),
            ),

            // All Screenshots lane
            SliverToBoxAdapter(
              child: ScreenshotLane(
                title: 'All Screenshots',
                items: allItems,
                onViewAll: allItems.isNotEmpty ? () {} : null,
              ),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Temp',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: 'Shot',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: AppColors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.greyDark, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home,
            index: 0,
            selected: selectedIndex == 0,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            index: 1,
            selected: selectedIndex == 1,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            index: 2,
            selected: selectedIndex == 2,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Icon(
          icon,
          color: selected ? AppColors.red : AppColors.grey,
          size: 24,
        ),
      ),
    );
  }
}
