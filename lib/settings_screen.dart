import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'Theme/app_theme.dart';
import 'Providers/screenshot_providers.dart';

class _SettingsState {
  final Duration defaultExpiry;
  final bool autoDeleteEnabled;
  final bool notificationsEnabled;
  final bool overlayEnabled;
  final bool deleteOnExpiry;
  final bool showExpiryBadge;

  const _SettingsState({
    this.defaultExpiry = const Duration(hours: 24),
    this.autoDeleteEnabled = true,
    this.notificationsEnabled = true,
    this.overlayEnabled = true,
    this.deleteOnExpiry = true,
    this.showExpiryBadge = true,
  });

  _SettingsState copyWith({
    Duration? defaultExpiry,
    bool? autoDeleteEnabled,
    bool? notificationsEnabled,
    bool? overlayEnabled,
    bool? deleteOnExpiry,
    bool? showExpiryBadge,
  }) => _SettingsState(
    defaultExpiry: defaultExpiry ?? this.defaultExpiry,
    autoDeleteEnabled: autoDeleteEnabled ?? this.autoDeleteEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    overlayEnabled: overlayEnabled ?? this.overlayEnabled,
    deleteOnExpiry: deleteOnExpiry ?? this.deleteOnExpiry,
    showExpiryBadge: showExpiryBadge ?? this.showExpiryBadge,
  );
}

class _SettingsNotifier extends StateNotifier<_SettingsState> {
  _SettingsNotifier() : super(const _SettingsState());

  void setDefaultExpiry(Duration d) => state = state.copyWith(defaultExpiry: d);
  void toggleAutoDelete(bool v) => state = state.copyWith(autoDeleteEnabled: v);
  void toggleNotifications(bool v) =>
      state = state.copyWith(notificationsEnabled: v);
  void toggleOverlay(bool v) => state = state.copyWith(overlayEnabled: v);
  void toggleDeleteOnExpiry(bool v) =>
      state = state.copyWith(deleteOnExpiry: v);
  void toggleExpiryBadge(bool v) => state = state.copyWith(showExpiryBadge: v);
}

final _settingsProvider =
    StateNotifierProvider<_SettingsNotifier, _SettingsState>(
      (_) => _SettingsNotifier(),
    );

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(_settingsProvider);
    final notifier = ref.read(_settingsProvider.notifier);
    final all = ref.watch(screenshotProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            title: const _ScreenTitle(title: 'Settings'),
          ),

          SliverToBoxAdapter(
            child: _AppInfoCard(
              controller: _rippleController,
              total: all.length,
            ),
          ),

          _sectionHeader('Default Expiry'),
          SliverToBoxAdapter(
            child: _ExpirySelector(
              current: settings.defaultExpiry,
              onChanged: notifier.setDefaultExpiry,
            ),
          ),

          _sectionHeader('Behaviour'),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _ToggleTile(
                  icon: Icons.auto_delete_outlined,
                  iconColor: AppColors.red,
                  title: 'Auto Delete',
                  subtitle:
                      'Automatically delete screenshots when timer expires',
                  value: settings.autoDeleteEnabled,
                  onChanged: notifier.toggleAutoDelete,
                ),
                _ToggleTile(
                  icon: Icons.delete_forever_outlined,
                  iconColor: AppColors.red,
                  title: 'Delete File on Expiry',
                  subtitle: 'Remove the actual file, not just the record',
                  value: settings.deleteOnExpiry,
                  onChanged: notifier.toggleDeleteOnExpiry,
                ),
              ],
            ),
          ),

          _sectionHeader('Notifications'),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _ToggleTile(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFF4FC3F7),
                  title: 'Push Notifications',
                  subtitle: 'Show notification for each new screenshot',
                  value: settings.notificationsEnabled,
                  onChanged: notifier.toggleNotifications,
                ),
                _ToggleTile(
                  icon: Icons.picture_in_picture_alt_outlined,
                  iconColor: const Color(0xFF81C784),
                  title: 'Floating Overlay',
                  subtitle: 'Show time-picker bubble over other apps',
                  value: settings.overlayEnabled,
                  onChanged: notifier.toggleOverlay,
                ),
                _ToggleTile(
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.amber,
                  title: 'Expiry Badge',
                  subtitle: 'Show countdown badge on screenshot thumbnails',
                  value: settings.showExpiryBadge,
                  onChanged: notifier.toggleExpiryBadge,
                ),
              ],
            ),
          ),

          _sectionHeader('Danger Zone'),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _ActionTile(
                  icon: Icons.cleaning_services_outlined,
                  iconColor: AppColors.amber,
                  title: 'Clear Expired Records',
                  subtitle: 'Remove all expired entries from the database',
                  onTap: () => _confirmAction(
                    context,
                    'Clear Expired Records',
                    'This will remove all expired records. Files already deleted.',
                    () => ref
                        .read(screenshotProvider.notifier)
                        .runAutoDeletePass(),
                  ),
                ),
                _ActionTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: AppColors.red,
                  title: 'Delete All Screenshots',
                  subtitle: 'Permanently delete all tracked screenshots',
                  onTap: () => _confirmAction(
                    context,
                    'Delete Everything',
                    'This will permanently delete ALL tracked screenshots from your device. This cannot be undone.',
                    () async {
                      final items = ref.read(screenshotProvider);
                      for (final item in items) {
                        await ref
                            .read(screenshotProvider.notifier)
                            .deleteScreenshot(item.id);
                      }
                    },
                    isDanger: true,
                  ),
                ),
              ],
            ),
          ),

          _sectionHeader('About'),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  value: '1.0.0',
                ),
                _InfoTile(
                  icon: Icons.storage_outlined,
                  title: 'Database',
                  value: 'Hive (Local)',
                ),
                _InfoTile(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'Privacy',
                  value: 'All data on-device',
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
  );

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: AppColors.white)),
        content: Text(message, style: const TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'Confirm',
              style: TextStyle(
                color: isDanger ? AppColors.red : AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  final AnimationController controller;
  final int total;

  const _AppInfoCard({required this.controller, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _SettingsRipplePainter(progress: controller.value),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.screenshot_monitor,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'TempShot',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total screenshots tracked  •  All data stored locally',
                style: const TextStyle(color: AppColors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsRipplePainter extends CustomPainter {
  final double progress;
  _SettingsRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 4; i++) {
      final p = ((progress + i / 4.0) % 1.0);
      final radius = size.width * 0.7 * p;
      final opacity = (1.0 - p) * 0.12;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.red.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SettingsRipplePainter old) => old.progress != progress;
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.greyDark,
              indent: 56,
            );
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.grey, fontSize: 11),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.red,
        inactiveThumbColor: AppColors.grey,
        inactiveTrackColor: AppColors.greyDark,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: iconColor == AppColors.red ? AppColors.red : AppColors.white,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.grey, fontSize: 11),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey,
        size: 18,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.grey, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
      ),
      trailing: Text(
        value,
        style: const TextStyle(color: AppColors.grey, fontSize: 13),
      ),
    );
  }
}

class _ExpirySelector extends StatelessWidget {
  final Duration current;
  final ValueChanged<Duration> onChanged;

  const _ExpirySelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = expiryOptions.entries
        .where((e) => e.value != null)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((e) {
          final isSelected = e.value == current;
          return GestureDetector(
            onTap: () => onChanged(e.value!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.red : AppColors.greyDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.red
                      : AppColors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                e.key,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.greyLight,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
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
          const TextSpan(
            text: 'Temp',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(
            text: 'Shot',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '  $title',
            style: const TextStyle(
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
