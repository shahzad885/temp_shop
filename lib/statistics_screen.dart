import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Providers/screenshot_providers.dart';
import 'Theme/app_theme.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _countController;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );
    _countController.forward();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(screenshotProvider);
    final expiring = ref.watch(expiringSoonProvider);
    final vault = ref.watch(vaultScreenshotsProvider);
    final otp = ref.watch(otpScreenshotsProvider);

    final totalDeleted = 47; // static demo value
    final savedMB = (totalDeleted * 2.4).toStringAsFixed(1);
    final totalTracked = all.length;
    final pendingCount = all.where((i) => i.expiryDate == null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            title: const _ScreenTitle(title: 'Statistics'),
            centerTitle: false,
          ),

          SliverToBoxAdapter(
            child: _RippleHeroStat(
              controller: _rippleController,
              countAnimation: _countAnimation,
              value: totalDeleted,
              label: 'Screenshots Deleted',
              sublabel: '$savedMB MB freed from your device',
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _StatCard(
                  icon: Icons.photo_library_outlined,
                  label: 'Tracked',
                  value: totalTracked,
                  color: const Color(0xFF4FC3F7),
                  animation: _countAnimation,
                ),
                _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Expiring Soon',
                  value: expiring.length,
                  color: AppColors.red,
                  animation: _countAnimation,
                ),
                _StatCard(
                  icon: Icons.lock_outline,
                  label: 'In Vault',
                  value: vault.length,
                  color: AppColors.amber,
                  animation: _countAnimation,
                ),
                _StatCard(
                  icon: Icons.pending_outlined,
                  label: 'Pending',
                  value: pendingCount,
                  color: const Color(0xFF81C784),
                  animation: _countAnimation,
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
            ),
          ),

          SliverToBoxAdapter(child: _WeeklyChart(animation: _countAnimation)),

          SliverToBoxAdapter(
            child: _StorageBreakdown(
              totalTracked: totalTracked,
              expiring: expiring.length,
              vault: vault.length,
              otp: otp.length,
              animation: _countAnimation,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _RippleHeroStat extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> countAnimation;
  final int value;
  final String label;
  final String sublabel;

  const _RippleHeroStat({
    required this.controller,
    required this.countAnimation,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(double.infinity, 260),
                  painter: _RipplePainter(
                    progress: controller.value,
                    color: AppColors.red,
                  ),
                );
              },
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: countAnimation,
                  builder: (_, __) {
                    final displayed = (value * countAnimation.value).round();
                    return Text(
                      '$displayed',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.65;

    for (int i = 0; i < 3; i++) {
      final offset = i / 3.0;
      final p = ((progress + offset) % 1.0);
      final radius = maxRadius * p;
      final opacity = (1.0 - p) * 0.25;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, paint);

      // Also draw filled version near center for glow effect
      if (p < 0.3) {
        final fillPaint = Paint()
          ..color = color.withOpacity((0.3 - p) * 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, fillPaint);
      }
    }

    // Center dot glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 50, glowPaint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Animation<double> animation;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (_, __) {
                  return Text(
                    '${(value * animation.value).round()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Animation<double> animation;

  const _WeeklyChart({required this.animation});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [3, 7, 2, 9, 5, 12, 4];
    final maxVal = values.reduce(max).toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deleted This Week',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(days.length, (i) {
                  final heightFraction = (values[i] / maxVal) * animation.value;
                  final isToday = i == 6;
                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 100 * heightFraction,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.red
                              : AppColors.red.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: TextStyle(
                          color: isToday ? AppColors.white : AppColors.grey,
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StorageBreakdown extends StatelessWidget {
  final int totalTracked, expiring, vault, otp;
  final Animation<double> animation;

  const _StorageBreakdown({
    required this.totalTracked,
    required this.expiring,
    required this.vault,
    required this.otp,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BreakdownItem('Expiring Soon', expiring, AppColors.red),
      _BreakdownItem('In Vault', vault, AppColors.amber),
      _BreakdownItem('OTP / Codes', otp, const Color(0xFF4FC3F7)),
      _BreakdownItem(
        'Pending',
        totalTracked - expiring - vault - otp,
        const Color(0xFF81C784),
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Screenshot Breakdown',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => _BreakdownRow(item: item, animation: animation),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final int count;
  final Color color;
  const _BreakdownItem(this.label, this.count, this.color);
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownItem item;
  final Animation<double> animation;

  const _BreakdownRow({required this.item, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 13,
                ),
              ),
              Text(
                '${item.count}',
                style: TextStyle(
                  color: item.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final fraction = item.count == 0 ? 0.0 : animation.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction * (item.count / 20.0).clamp(0.05, 1.0),
                  backgroundColor: AppColors.greyDark,
                  valueColor: AlwaysStoppedAnimation(item.color),
                  minHeight: 6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  final String title;
  const _ScreenTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Temp',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: 'Shot',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '  $title',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
