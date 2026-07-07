import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models/course.dart';
import '../../state/providers.dart';
import 'level_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.course, required this.level});

  final Course course;
  final Level level;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final List<Question> _questions;
  final Map<String, int?> _answers = {};
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Randomised question order per run keeps replays fresh.
    _questions = [...widget.level.questions]..shuffle(Random());
  }

  Question get _current => _questions[_index];
  int? get _selected => _answers[_current.id];
  bool get _isLast => _index == _questions.length - 1;

  void _select(int option) =>
      setState(() => _answers[_current.id] = option);

  void _goPrevious() {
    if (_index > 0) setState(() => _index--);
  }

  void _skip() {
    _answers.putIfAbsent(_current.id, () => null);
    _advance();
  }

  void _next() {
    if (_selected == null) return;
    _advance();
  }

  void _advance() {
    if (!_isLast) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final courses = ref.read(coursesProvider).value ?? [widget.course];
    final outcome = ref.read(progressProvider.notifier).recordAttempt(
          course: widget.course,
          level: widget.level,
          answers: _answers,
          allCourses: courses,
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelResultScreen(
          course: widget.course,
          level: widget.level,
          outcome: outcome,
          questions: _questions,
          answers: Map.of(_answers),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this level?'),
        content: const Text('Your answers in this run will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _showHelp() {
    final resource = _current.resource;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Get unstuck',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'This question is about "${_current.topic}". Review the source '
              'material, then come back and finish the level — your answers '
              'are kept while you read.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (resource != null)
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(resource.title),
                onPressed: () => launchUrl(Uri.parse(resource.url),
                    mode: LaunchMode.externalApplication),
              )
            else
              Text(
                'No linked resource for this one — trust your instincts!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
          title: Text('${widget.level.title} · ${_index + 1}/${_questions.length}'),
          actions: [
            IconButton(
              tooltip: 'Get unstuck',
              icon: const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.gold),
              onPressed: _showHelp,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ArenaProgressBar(
                value: (_index + 1) / _questions.length,
                color: widget.course.color,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      children: [
                        StatChip(
                          icon: Icons.category_rounded,
                          label: _current.topic,
                          color: widget.course.color,
                        ),
                        const SizedBox(height: 14),
                        Text(_current.question,
                            style: textTheme.headlineMedium),
                        const SizedBox(height: 22),
                        for (var i = 0; i < _current.options.length; i++) ...[
                          _OptionTile(
                            letter: String.fromCharCode(65 + i),
                            text: _current.options[i],
                            selected: _selected == i,
                            onTap: () => _select(i),
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
                            onPressed: _index > 0 ? _goPrevious : null,
                            style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: const Tooltip(
                              message: 'Previous question',
                              child: Icon(Icons.arrow_back_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skip,
                            child: Text(_isLast ? 'Skip & finish' : 'Skip'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _selected != null ? _next : null,
                            child: Text(_isLast ? 'Finish' : 'Next'),
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
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.14)
            : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.gold : scheme.outline,
          width: selected ? 2 : 1,
        ),
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
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.gold
                        : scheme.outline.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.ink : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(text,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
