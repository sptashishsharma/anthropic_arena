import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../gamification/badges.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authProvider);
    final progress = ref.watch(progressProvider);
    final themeMode = ref.watch(themeProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (player == null) return const SizedBox.shrink();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              PlayerAvatar(initial: player.initial, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineMedium),
                        ),
                        const SizedBox(width: 8),
                        Text(player.tag,
                            style: textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StatChip(
                      icon: switch (player.provider.name) {
                        'google' => Icons.g_mobiledata_rounded,
                        'apple' => Icons.apple_rounded,
                        'email' => Icons.mail_rounded,
                        _ => Icons.sports_esports_rounded,
                      },
                      label: switch (player.provider.name) {
                        'google' => 'Google (demo)',
                        'apple' => 'Apple (demo)',
                        'email' => player.email ?? 'Email',
                        _ => 'Guest player',
                      },
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit name',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => _editName(context, ref, player.name),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text('${progress.xp}',
                          style: textTheme.headlineSmall
                              ?.copyWith(color: AppColors.gold)),
                      Text('XP', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text('${progress.streakDays}',
                          style: textTheme.headlineSmall
                              ?.copyWith(color: const Color(0xFFFF7A45))),
                      Text('Streak', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArenaCard(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text('${progress.badges.length}',
                          style: textTheme.headlineSmall
                              ?.copyWith(color: AppColors.success)),
                      Text('Badges', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Badges'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final badge in Badges.all)
                Tooltip(
                  message: '${badge.name}\n${badge.description}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: progress.badges.contains(badge.id)
                          ? AppColors.gold.withValues(alpha: 0.16)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: progress.badges.contains(badge.id)
                            ? AppColors.gold
                            : scheme.outline,
                      ),
                    ),
                    child: Icon(
                      progress.badges.contains(badge.id)
                          ? badge.icon
                          : Icons.lock_outline_rounded,
                      color: progress.badges.contains(badge.id)
                          ? AppColors.gold
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle('Settings'),
          const SizedBox(height: 12),
          ArenaCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.smartphone_rounded),
                        label: Text('Auto')),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (set) =>
                      ref.read(themeProvider.notifier).set(set.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ArenaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Streak reminders'),
                  subtitle:
                      const Text('Push notifications arrive with Firebase'),
                  trailing: Switch(value: false, onChanged: null),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.restart_alt_rounded, color: AppColors.danger),
                  title: const Text('Reset progress',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () => _confirmReset(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const BrandMark(size: 40),
                const SizedBox(height: 6),
                Text('Anthropic Arena · v0.1.0',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text('Built by SPTECH USA · Jaipur',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.length >= 2) {
      ref.read(authProvider.notifier).rename(name);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'XP, streaks, stars and badges on this device will be erased. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).resetAll();
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}
