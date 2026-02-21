import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temp_shop/Theme/app_theme.dart';
import 'package:temp_shop/Widgets/hero_section.dart';
import 'package:temp_shop/Widgets/screenshot_lane.dart';
import 'package:temp_shop/Providers/screenshot_providers.dart';
import 'package:temp_shop/Screens/settings_screen.dart';
import 'package:temp_shop/Screens/statistics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _pages = [
    _DashboardPage(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiringSoon = ref.watch(expiringSoonProvider);
    final otpItems = ref.watch(otpScreenshotsProvider);
    final vaultItems = ref.watch(vaultScreenshotsProvider);
    final allItems = ref.watch(screenshotProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HeroSection()),

          SliverToBoxAdapter(
            child: ScreenshotLane(
              title: 'Expiring Soon',
              items: expiringSoon,
              badge: expiringSoon.isNotEmpty ? expiringSoon.length : null,
              onViewAll: expiringSoon.isNotEmpty ? () {} : null,
              accentColor: AppColors.red,
            ),
          ),

          SliverToBoxAdapter(
            child: ScreenshotLane(
              title: 'Smart Detected: OTPs',
              items: otpItems,
              badge: otpItems.isNotEmpty ? otpItems.length : null,
              onViewAll: otpItems.isNotEmpty ? () {} : null,
              accentColor: AppColors.amber,
            ),
          ),

          SliverToBoxAdapter(
            child: ScreenshotLane(
              title: 'The Vault',
              items: vaultItems,
              badge: vaultItems.isNotEmpty ? vaultItems.length : null,
              onViewAll: vaultItems.isNotEmpty ? () {} : null,
              accentColor: AppColors.amber,
            ),
          ),

          SliverToBoxAdapter(
            child: ScreenshotLane(
              title: 'All Screenshots',
              items: allItems,
              onViewAll: allItems.isNotEmpty ? () {} : null,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.greyDark, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            label: 'Home',
            index: 0,
            selected: selectedIndex == 0,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            index: 1,
            selected: selectedIndex == 1,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
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
  final String label;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.red : AppColors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.red : AppColors.grey,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
