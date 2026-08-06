import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
import '../../data/models/certification.dart';
import '../../data/models/player.dart';
import '../../data/models/progress.dart';
import '../../state/providers.dart';
import '../auth/login_screen.dart';
import '../auth/sign_in_options.dart';
import 'cert_exam_screen.dart';

/// The order categories are shown in the tab. Any category not listed here
/// falls to the end (alphabetically).
const _categoryOrder = [
  'Associate / Foundations',
  'Administrator & App Builder',
  'Developer',
  'Consultant',
  'Marketing',
  'Artificial Intelligence',
  'Architect',
];

class CertificationTab extends ConsumerWidget {
  const CertificationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(authProvider);
    // Gate: certification exam banks require a real (non-guest) account.
    final signedIn = player != null && player.provider != AuthProvider.guest;
    if (!signedIn) {
      return const SafeArea(child: _SignInGate());
    }

    final certs = ref.watch(certificationsProvider);
    final progress = ref.watch(progressProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: certs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Could not load certifications\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          final grouped = _group(list);
          return ContentShell(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              Text('Certifications', style: textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Pick a credential and take a timed practice exam.',
                style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              for (final category in grouped.keys) ...[
                _CategoryHeader(
                  title: category,
                  count: grouped[category]!.length,
                ),
                const SizedBox(height: 12),
                ResponsiveCardGrid(
                  spacing: 12,
                  children: [
                    for (final cert in grouped[category]!)
                      _CertCard(
                        cert: cert,
                        best: progress.bestCertAttempt(cert.id),
                        attempts: progress.certAttemptsFor(cert.id).length,
                        onTap: () => _showExamSheet(context, cert, progress),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
            ),
          );
        },
      ),
    );
  }

  /// Groups certifications by category, ordering categories by
  /// [_categoryOrder] and each category's certs by their `order`.
  Map<String, List<Certification>> _group(List<Certification> certs) {
    final byCategory = <String, List<Certification>>{};
    for (final c in certs) {
      byCategory.putIfAbsent(c.category, () => []).add(c);
    }
    for (final entry in byCategory.values) {
      entry.sort((a, b) => a.order.compareTo(b.order));
    }
    final ordered = <String, List<Certification>>{};
    for (final cat in _categoryOrder) {
      if (byCategory.containsKey(cat)) ordered[cat] = byCategory.remove(cat)!;
    }
    // Any remaining categories, alphabetically.
    for (final cat in byCategory.keys.toList()..sort()) {
      ordered[cat] = byCategory[cat]!;
    }
    return ordered;
  }

  void _showExamSheet(
      BuildContext context, Certification cert, UserProgress progress) {
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: GlassSurface(
          radius: 28,
          glow: cert.color,
          glowAlpha: 0.35,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _CertBadge(color: cert.color, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cert.name, style: textTheme.headlineSmall),
                        Text(cert.tagline,
                            style: textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatChip(
                    icon: Icons.help_outline_rounded,
                    label: '${cert.scoredCount} scored Q',
                    color: cert.color,
                  ),
                  StatChip(
                    icon: Icons.timer_outlined,
                    label: '${cert.timeLimitMinutes} min',
                    color: AppColors.info,
                  ),
                  StatChip(
                    icon: Icons.verified_outlined,
                    label: 'Pass ${cert.passMark}%',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoLine(
                icon: Icons.info_outline_rounded,
                text: 'Official format: ${cert.scoredCount} '
                    'multiple-choice / multiple-select questions'
                    '${cert.unscoredCount > 0 ? ' plus up to ${cert.unscoredCount} unscored' : ''}, '
                    '${cert.timeLimitMinutes} minutes, pass at ${cert.passMark}%.',
              ),
              if (cert.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoLine(icon: Icons.push_pin_outlined, text: cert.note),
              ],
              const SizedBox(height: 16),
              ..._launcher(context, sheetContext, cert, progress),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the "how to start" section of the sheet: a single Start button, a
  /// set picker when there is more than one set, or a disabled state when the
  /// track is retired / has no questions yet.
  List<Widget> _launcher(BuildContext context, BuildContext sheetContext,
      Certification cert, UserProgress progress) {
    if (cert.retired) {
      return [
        const _InfoLine(
          icon: Icons.block_rounded,
          text: 'This credential has been retired by Salesforce and is shown '
              'here for reference only.',
        ),
        const SizedBox(height: 18),
        _disabledButton(context, cert, 'Retired', Icons.block_rounded),
      ];
    }

    final sets = cert.playableSets;
    if (sets.isEmpty) {
      return [
        const _InfoLine(
          icon: Icons.hourglass_empty_rounded,
          text: 'Practice questions for this track are being added — check '
              'back soon.',
        ),
        const SizedBox(height: 18),
        _disabledButton(
            context, cert, 'Questions coming soon', Icons.lock_clock_rounded),
      ];
    }

    if (sets.length == 1) {
      final set = sets.first;
      final n = cert.scoredCountFor(set);
      return [
        _InfoLine(
          icon: Icons.bolt_rounded,
          text: 'This exam draws $n random question${n == 1 ? '' : 's'} from '
              'the ${set.questions.length}-question pool. The timer starts '
              'immediately and auto-submits at 0:00.',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start exam'),
          style: FilledButton.styleFrom(
            backgroundColor: cert.color,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _start(context, sheetContext, cert, set),
        ),
      ];
    }

    return [
      _InfoLine(
        icon: Icons.layers_rounded,
        text: 'This certification has ${sets.length} exam sets. Each exam '
            'draws ${cert.scoredCount} random questions from the set you pick.',
      ),
      const SizedBox(height: 14),
      Text('Choose an exam set',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      for (final set in sets) ...[
        _SetOptionTile(
          cert: cert,
          set: set,
          best: _bestForSet(progress, cert.id, set.id),
          onTap: () => _start(context, sheetContext, cert, set),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  void _start(BuildContext context, BuildContext sheetContext,
      Certification cert, ExamSet set) {
    Navigator.of(sheetContext).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertExamScreen(certification: cert, examSet: set),
      ),
    );
  }

  Widget _disabledButton(
      BuildContext context, Certification cert, String label, IconData icon) {
    return FilledButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: cert.color,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
      ),
      onPressed: null,
    );
  }

  CertAttempt? _bestForSet(UserProgress progress, String certId, String setId) {
    CertAttempt? best;
    for (final a in progress.certAttemptsFor(certId)) {
      if (a.setId != setId) continue;
      if (best == null || a.scorePct > best.scorePct) best = a;
    }
    return best;
  }
}

/// A selectable exam set inside the picker sheet.
class _SetOptionTile extends StatelessWidget {
  const _SetOptionTile({
    required this.cert,
    required this.set,
    required this.best,
    required this.onTap,
  });

  final Certification cert;
  final ExamSet set;
  final CertAttempt? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final n = cert.scoredCountFor(set);
    final date = _formatDate(set.dateIso);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cert.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cert.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.style_rounded, color: cert.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.label, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${set.questions.length} in pool · draws $n'
                      '${date.isEmpty ? '' : ' · $date'}'
                      '${best == null ? '' : ' · best ${best!.scorePct}%'}',
                      style: textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded, color: cert.color),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _CertCard extends StatelessWidget {
  const _CertCard({
    required this.cert,
    required this.best,
    required this.attempts,
    required this.onTap,
  });

  final Certification cert;
  final CertAttempt? best;
  final int attempts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dimmed = !cert.isPlayable;

    return Opacity(
      opacity: dimmed ? 0.66 : 1,
      child: GlassSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        glow: best?.passed == true ? cert.color : null,
        glowAlpha: 0.18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CertBadge(color: cert.color, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.name, style: textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(cert.tagline,
                          style: textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                StatChip(
                  icon: Icons.timer_outlined,
                  label: '${cert.timeLimitMinutes} min',
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                StatChip(
                  icon: Icons.verified_outlined,
                  label: 'Pass ${cert.passMark}%',
                  color: AppColors.success,
                ),
                const Spacer(),
                _StatusLabel(cert: cert, best: best),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The trailing status on a cert card: best score, retired, coming soon, or
/// not-yet-attempted.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.cert, required this.best});

  final Certification cert;
  final CertAttempt? best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (cert.retired) {
      return _iconText(Icons.block_rounded, 'Retired', muted, textTheme);
    }
    if (!cert.isPlayable) {
      return _iconText(
          Icons.hourglass_empty_rounded, 'Coming soon', muted, textTheme);
    }
    if (best != null) {
      final c = best!.passed ? AppColors.success : AppColors.danger;
      return _iconText(
        best!.passed
            ? Icons.emoji_events_rounded
            : Icons.timelapse_rounded,
        'Best ${best!.scorePct}%',
        c,
        textTheme,
      );
    }
    return Text('Not attempted',
        style: textTheme.labelMedium?.copyWith(color: muted));
  }

  Widget _iconText(
      IconData icon, String label, Color color, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CertBadge extends StatelessWidget {
  const _CertBadge({required this.color, this.size = 52});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Icon(Icons.workspace_premium_rounded,
          color: Colors.white, size: size * 0.5),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// Shown on the Certifications tab when the user is a guest (or not signed in).
/// The certification exam banks are members-only, so guests are prompted to
/// sign in with a real account before the catalog is revealed.
///
/// The sign-in buttons are embedded **here**, not behind a redirect: signing in
/// on this screen flips `authProvider`, which rebuilds [CertificationTab] and
/// reveals the catalogue in place. That keeps unlocking the tab from depending
/// on a route push at all. "Open the full sign-in page" stays as a secondary
/// way out for anyone who wants the standalone screen.
///
/// Layout matters here: a bare `Center` + `SingleChildScrollView` silently
/// pushes whatever doesn't fit below the fold, and on a short viewport that put
/// the sign-in button underneath the bottom `NavigationBar`, which then ate the
/// tap — the button looked present but did nothing. The `LayoutBuilder` +
/// `minHeight` pattern below centres the card when it fits and scrolls it when
/// it doesn't, and the copy is kept short so the buttons stay above the fold on
/// a phone-sized window. Keep it that way when editing this screen.
class _SignInGate extends StatelessWidget {
  const _SignInGate();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 32).clamp(0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassSurface(
                radius: 28,
                glow: AppColors.gold,
                glowAlpha: 0.32,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 44, color: AppColors.gold),
                    const SizedBox(height: 12),
                    Text('Sign in to unlock Certifications',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Practice exams are for signed-in members. Your XP, '
                      'streak and stars come with you.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    // Guests are already an anonymous session, so "Play as
                    // guest" is hidden — it would leave this tab locked.
                    const SignInOptions(showGuest: false),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Open the full sign-in page'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
