import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/glass.dart';
import '../../data/models/certification.dart';
import '../../state/providers.dart';
import 'cert_result_screen.dart';

class CertExamScreen extends ConsumerStatefulWidget {
  const CertExamScreen({
    super.key,
    required this.certification,
    required this.examSet,
  });

  final Certification certification;
  final ExamSet examSet;

  @override
  ConsumerState<CertExamScreen> createState() => _CertExamScreenState();
}

class _CertExamScreenState extends ConsumerState<CertExamScreen> {
  late final List<CertQuestion> _questions;
  final Map<String, Set<int>> _answers = {};
  late final int _totalSeconds;

  Timer? _ticker;
  int _remaining = 0;
  int _index = 0;
  bool _submitted = false;

  Certification get _cert => widget.certification;

  @override
  void initState() {
    super.initState();
    // Randomly draw the scored questions from the chosen set's pool.
    final pool = [...widget.examSet.questions]..shuffle(Random());
    _questions =
        pool.take(widget.certification.scoredCountFor(widget.examSet)).toList();
    _totalSeconds = widget.certification.timeLimitMinutes * 60;
    _remaining = _totalSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() => _remaining--);
    if (_remaining <= 0) _submit(auto: true);
  }

  CertQuestion get _current => _questions[_index];
  int get _answeredCount =>
      _questions.where((q) => (_answers[q.id]?.isNotEmpty ?? false)).length;
  bool get _isLast => _index == _questions.length - 1;

  void _toggle(int option) {
    final q = _current;
    final set = _answers.putIfAbsent(q.id, () => <int>{});
    setState(() {
      if (q.isMultiSelect) {
        set.contains(option) ? set.remove(option) : set.add(option);
      } else {
        set
          ..clear()
          ..add(option);
      }
    });
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (!_isLast) setState(() => _index++);
  }

  void _jumpTo(int i) => setState(() => _index = i);

  Future<void> _submit({required bool auto}) async {
    if (_submitted) return;
    _submitted = true;
    _ticker?.cancel();

    final attempt = ref.read(progressProvider.notifier).recordCertAttempt(
          cert: _cert,
          set: widget.examSet,
          questions: _questions,
          answers: _answers,
          durationSeconds: _totalSeconds - _remaining.clamp(0, _totalSeconds),
          autoSubmitted: auto,
        );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CertResultScreen(
          certification: _cert,
          examSet: widget.examSet,
          questions: _questions,
          answers: {
            for (final e in _answers.entries) e.key: {...e.value}
          },
          attempt: attempt,
        ),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _questions.length - _answeredCount;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit exam?'),
        content: Text(unanswered == 0
            ? 'All ${_questions.length} questions answered. Submit for scoring?'
            : '$unanswered of ${_questions.length} question'
                '${unanswered == 1 ? '' : 's'} still unanswered. '
                'Unanswered questions are marked incorrect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (go == true) _submit(auto: false);
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave the exam?'),
        content: const Text(
            'Your exam will be discarded and not scored. The timer stops.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _ticker?.cancel();
      Navigator.of(context).pop();
    }
  }

  void _openPalette() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(12),
        child: GlassSurface(
          radius: 26,
          glow: _cert.color,
          glowAlpha: 0.3,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Questions',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Text('$_answeredCount / ${_questions.length} answered',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _questions.length; i++)
                    _PaletteCell(
                      number: i + 1,
                      current: i == _index,
                      answered: _answers[_questions[i].id]?.isNotEmpty ?? false,
                      color: _cert.color,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _jumpTo(i);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Review & submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: _cert.color,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _confirmSubmit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    final s = seconds.clamp(0, _totalSeconds);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final q = _current;
    final selected = _answers[q.id] ?? const <int>{};
    final lowTime = _remaining <= 300;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmExit,
          ),
          title: Text('${_cert.name} · ${_index + 1}/${_questions.length}'),
          actions: [
            Center(child: _TimerChip(text: _fmt(_remaining), low: lowTime)),
            IconButton(
              tooltip: 'All questions',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: _openPalette,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ArenaProgressBar(
                value: (_index + 1) / _questions.length,
                color: _cert.color,
              ),
            ),
          ),
        ),
        body: NeonBackground(
          accent: _cert.color,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        children: [
                          Row(
                            children: [
                              StatChip(
                                icon: Icons.category_rounded,
                                label: q.topic,
                                color: _cert.color,
                              ),
                              const Spacer(),
                              if (q.isMultiSelect)
                                StatChip(
                                  icon: Icons.check_box_outlined,
                                  label: 'Select ${q.correctIndexes.length}',
                                  color: AppColors.info,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(q.question, style: textTheme.headlineSmall),
                          if (q.isMultiSelect) ...[
                            const SizedBox(height: 6),
                            Text('Select all that apply.',
                                style: textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                          const SizedBox(height: 20),
                          for (var i = 0; i < q.options.length; i++) ...[
                            _OptionTile(
                              letter: String.fromCharCode(65 + i),
                              text: q.options[i],
                              selected: selected.contains(i),
                              multi: q.isMultiSelect,
                              accent: _cert.color,
                              onTap: () => _toggle(i),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: OutlinedButton(
                              onPressed: _index > 0 ? _prev : null,
                              style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _isLast
                                ? FilledButton.icon(
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded),
                                    label: const Text('Review & submit'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _cert.color,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _confirmSubmit,
                                  )
                                : FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _cert.color,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _next,
                                    child: const Text('Next'),
                                  ),
                          ),
                        ],
                      ),
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

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.text, required this.low});

  final String text;
  final bool low;

  @override
  Widget build(BuildContext context) {
    final color = low ? AppColors.danger : AppColors.gold;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: -2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _PaletteCell extends StatelessWidget {
  const _PaletteCell({
    required this.number,
    required this.current,
    required this.answered,
    required this.color,
    required this.onTap,
  });

  final int number;
  final bool current;
  final bool answered;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final Color border;
    if (current) {
      bg = color;
      fg = Colors.white;
      border = color;
    } else if (answered) {
      bg = color.withValues(alpha: 0.18);
      fg = scheme.onSurface;
      border = color.withValues(alpha: 0.5);
    } else {
      bg = scheme.onSurface.withValues(alpha: 0.05);
      fg = scheme.onSurfaceVariant;
      border = scheme.onSurface.withValues(alpha: 0.15);
    }
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Text('$number',
                style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.multi,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool multi;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.16)
            : scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accent : scheme.outline,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: -3),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _Marker(
                    letter: letter,
                    selected: selected,
                    multi: multi,
                    accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      Text(text, style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.letter,
    required this.selected,
    required this.multi,
    required this.accent,
  });

  final String letter;
  final bool selected;
  final bool multi;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Square-ish for multi-select (checkbox), circle for single (radio).
        shape: multi ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multi ? BorderRadius.circular(8) : null,
        color: selected ? accent : scheme.outline.withValues(alpha: 0.35),
      ),
      child: selected
          ? Icon(multi ? Icons.check_rounded : Icons.circle,
              size: multi ? 20 : 12, color: Colors.white)
          : Text(letter,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: scheme.onSurface)),
    );
  }
}
