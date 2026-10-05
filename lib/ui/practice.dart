import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/content.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import '../state/store.dart';
import 'exam_runner.dart';
import 'flashcards.dart';
import 'paywall.dart';
import 'question_view.dart';
import 'scratchpad.dart';
import 'theme.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final store = context.watch<StoreManager>();
    final progress = context.watch<ProgressStore>();
    final content = context.read<Content>();
    final scheduler = context.watch<FlashcardScheduler>();
    final exam = settings.exam;
    final due = scheduler.totalDue(exam);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Readable(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!settings.hasTakenDiagnostic) ...[
                const SectionHeader('Start here'),
                NavCard(
                  icon: Icons.monitor_heart_outlined,
                  color: Colors.orange,
                  title: 'Take the Diagnostic',
                  subtitle:
                      'Find your baseline score in about ${_diagnosticMinutes(settings)} minutes',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => const DiagnosticIntroScreen())),
                ),
              ],
              const SectionHeader('Drills'),
              NavCard(
                icon: Icons.timer_rounded,
                color: Colors.purple,
                title: 'Mock Exams',
                subtitle: '${exam.mockExamCount} exams · Quick or Full-Length',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => const MockExamsScreen())),
              ),
              const SizedBox(height: 10),
              NavCard(
                icon: Icons.style_rounded,
                color: Theme.of(context).colorScheme.primary,
                title: 'Flashcards',
                subtitle: due > 0 ? '$due card${due == 1 ? '' : 's'} due for review' : 'Spaced-repetition decks',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => const FlashcardsScreen())),
              ),
              if (settings.hasTakenDiagnostic) ...[
                const SizedBox(height: 10),
                NavCard(
                  icon: Icons.replay_rounded,
                  color: Colors.orange,
                  title: 'Retake Diagnostic',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => const DiagnosticIntroScreen())),
                ),
              ],
              const SectionHeader('Practice by subject'),
              for (final s in exam.subjects) ...[
                Builder(builder: (context) {
                  final total = content.questionsFor(s).length;
                  final st = progress.practiceStats(s);
                  return NavCard(
                    icon: s.icon,
                    color: s.color,
                    title: s.displayName,
                    subtitle: st.attempted == 0
                        ? '${formatCount(total)} questions'
                        : '${st.attempted} answered · ${(st.correct * 100 / st.attempted).round()}% correct',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute<void>(builder: (_) => PracticeSetupScreen(subject: s))),
                  );
                }),
                const SizedBox(height: 10),
              ],
              if (!store.isPro)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                      'The free plan includes the first ${AppConfig.freePracticeLimit} questions in each subject. Subscribe for all ${formatCount(content.countFor(exam))} ${exam.label} questions.',
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  int _diagnosticMinutes(AppSettings s) =>
      s.activeSubjects.fold(0, (n, x) => n + ExamMode.diagnostic.minutes(x));
}

// ----------------------------------------------------------------- Diagnostic

class DiagnosticIntroScreen extends StatelessWidget {
  const DiagnosticIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final subjects = settings.activeSubjects;
    final minutes = subjects.fold(0, (n, s) => n + ExamMode.diagnostic.minutes(s));
    final questions = subjects.fold(0, (n, s) => n + ExamMode.diagnostic.count(s));
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.monitor_heart_outlined, size: 56, color: Colors.orange),
            const SizedBox(height: 12),
            Text('Find your starting point',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'A short, timed placement test: $questions questions, about $minutes minutes. It estimates your ${settings.exam.label} score and highlights the topics to work on first. Free for everyone.',
                style: const TextStyle(height: 1.45, fontSize: 16)),
            const SectionHeader('Sections'),
            for (final s in subjects)
              Card(
                child: ListTile(
                  leading: IconBadge(s.icon, color: s.color),
                  title: Text(s.displayName),
                  subtitle: Text(
                      '${ExamMode.diagnostic.count(s)} questions · ${ExamMode.diagnostic.minutes(s)} min'),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          const ExamRunnerScreen(examIndex: 0, mode: ExamMode.diagnostic))),
              child: const Text('Begin'),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Mock exams

class MockExamsScreen extends StatelessWidget {
  const MockExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final store = context.watch<StoreManager>();
    final progress = context.watch<ProgressStore>();
    final exam = settings.exam;
    final subjects = settings.activeSubjects;

    int total(ExamMode m, int Function(Subject) f) => subjects.fold(0, (n, s) => n + f(s));
    final qQ = total(ExamMode.quick, ExamMode.quick.count);
    final qM = total(ExamMode.quick, ExamMode.quick.minutes);
    final fQ = total(ExamMode.full, ExamMode.full.count);
    final fM = total(ExamMode.full, ExamMode.full.minutes);

    return Scaffold(
      appBar: AppBar(title: const Text('Mock Exams')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                'Quick: $qQ questions in $qM minutes.\nFull-Length: $fQ questions in ${_hm(fM)}, with real ${exam.label} section timing.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 12),
            for (var i = 0; i < exam.mockExamCount; i++) ...[
              Builder(builder: (context) {
                final results = progress.resultsFor(exam).where((r) => r.examNumber == i + 1).toList();
                final best = results.isEmpty ? null : results.map((r) => r.composite).reduce(max);
                final unlocked = store.isExamUnlocked(i);
                return NavCard(
                  icon: Icons.assignment_rounded,
                  color: Colors.purple,
                  title: 'Mock Exam ${i + 1}',
                  subtitle: best == null ? (unlocked ? 'Not taken yet' : 'Pro') : 'Best score: $best',
                  locked: !unlocked,
                  onTap: () => unlocked ? _chooseMode(context, i, qQ, qM, fQ, fM) : showPaywall(context),
                );
              }),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ]),
    );
  }

  String _hm(int minutes) => minutes >= 60 ? '${minutes ~/ 60} hr ${minutes % 60} min' : '$minutes min';

  void _chooseMode(BuildContext context, int index, int qQ, int qM, int fQ, int fM) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Mock Exam ${index + 1}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            NavCard(
              icon: Icons.bolt_rounded,
              color: Colors.orange,
              title: 'Quick',
              subtitle: '$qQ questions · $qM minutes',
              onTap: () => _start(c, context, index, ExamMode.quick),
            ),
            const SizedBox(height: 10),
            NavCard(
              icon: Icons.hourglass_bottom_rounded,
              color: Colors.purple,
              title: 'Full-Length',
              subtitle: '$fQ questions · ${_hm(fM)}',
              onTap: () => _start(c, context, index, ExamMode.full),
            ),
          ]),
        ),
      ),
    );
  }

  void _start(BuildContext sheet, BuildContext context, int index, ExamMode mode) {
    Navigator.pop(sheet);
    Navigator.push(
        context, MaterialPageRoute<void>(builder: (_) => ExamRunnerScreen(examIndex: index, mode: mode)));
  }
}

// ----------------------------------------------------------- Subject practice

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key, required this.subject});
  final Subject subject;

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  String? _topic;
  int _count = 10;

  @override
  Widget build(BuildContext context) {
    final content = context.read<Content>();
    final store = context.watch<StoreManager>();
    final progress = context.watch<ProgressStore>();
    final subject = widget.subject;
    final topics = content.topicsFor(subject);
    final all = content.questionsFor(subject);

    List<Question> pool() {
      final out = <Question>[];
      for (var i = 0; i < all.length; i++) {
        final q = all[i];
        if (_topic != null && q.topic != _topic) continue;
        if (!store.isPracticeQuestionUnlocked(i)) continue;
        out.add(q);
      }
      return out;
    }

    final available = pool();
    final lockedCount = _topic == null
        ? all.length - available.length
        : all.where((q) => q.topic == _topic).length - available.length;
    final stats = {for (final t in progress.topicStats(subject)) t.topic: t};

    return Scaffold(
      appBar: AppBar(title: Text(subject.displayName)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Topic'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(
                  label: const Text('All topics'),
                  selected: _topic == null,
                  onSelected: (_) => setState(() => _topic = null)),
              for (final t in topics)
                ChoiceChip(
                  label: Text(stats[t] != null && stats[t]!.attempted > 0
                      ? '$t · ${(stats[t]!.accuracy * 100).round()}%'
                      : t),
                  selected: _topic == t,
                  onSelected: (_) => setState(() => _topic = t),
                ),
            ]),
            const SectionHeader('Number of questions'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 40, label: Text('40')),
              ],
              selected: {_count},
              onSelectionChanged: (s) => setState(() => _count = s.first),
            ),
            const SizedBox(height: 8),
            Text(
                'Unanswered and missed questions come first. ${formatCount(available.length)} available'
                '${lockedCount > 0 ? ' · $lockedCount more with Pro' : ''}.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            if (available.isEmpty)
              FilledButton(onPressed: () => showPaywall(context), child: const Text('Unlock with Pro'))
            else
              FilledButton(
                onPressed: () {
                  // Unanswered first, then missed, then correct; shuffled within each tier.
                  final rng = Random();
                  int tier(Question q) => switch (progress.outcomeFor(q.id)) {
                        null => 0,
                        false => 1,
                        true => 2
                      };
                  final sorted = [...available]..shuffle(rng);
                  sorted.sort((a, b) => tier(a).compareTo(tier(b)));
                  Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => PracticeSessionScreen(
                              title: subject.displayName, questions: sorted.take(_count).toList())));
                },
                child: const Text('Start'),
              ),
            if (lockedCount > 0) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: () => showPaywall(context), child: const Text('Unlock all questions')),
            ],
          ]),
        ),
      ]),
    );
  }
}

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.title, required this.questions});
  final String title;
  final List<Question> questions;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  int _i = 0;
  int? _selected;
  int _correct = 0;
  bool _done = false;
  final _started = DateTime.now();
  bool _logged = false;
  late final AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppSettings>();
  }

  void _log() {
    if (_logged) return;
    _logged = true;
    final secs = DateTime.now().difference(_started).inSeconds;
    // Notifies listeners, so defer it out of any build/dispose phase.
    Future.microtask(() => _settings.logPractice(secs));
  }

  @override
  void dispose() {
    _log();
    super.dispose();
  }

  void _answer(int choice) {
    if (_selected != null) return;
    final q = widget.questions[_i];
    final ok = choice == q.correctIndex;
    context.read<ProgressStore>().recordPractice(q.id, ok);
    setState(() {
      _selected = choice;
      if (ok) _correct++;
    });
  }

  void _next() {
    if (_i >= widget.questions.length - 1) {
      _log();
      setState(() => _done = true);
    } else {
      setState(() {
        _i++;
        _selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.read<Content>();
    if (_done) {
      final total = widget.questions.length;
      final pct = (_correct * 100 / total).round();
      return Scaffold(
        appBar: AppBar(title: const Text('Session Complete')),
        body: Center(
          child: Readable(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(pct >= 80 ? Icons.emoji_events_rounded : Icons.trending_up_rounded,
                  size: 64, color: pct >= 80 ? Colors.amber : Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('$_correct of $total correct',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Text('$pct%', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            ]),
          ),
        ),
      );
    }

    final q = widget.questions[_i];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} · ${_i + 1}/${widget.questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_i + (_selected != null ? 1 : 0)) / widget.questions.length),
        ),
        actions: [
          IconButton(
              tooltip: 'Scratchpad',
              icon: const Icon(Icons.draw_outlined),
              onPressed: () => showScratchpad(context, q.id)),
        ],
      ),
      body: QuestionView(
        key: ValueKey(q.id),
        question: q,
        passage: content.passageFor(q),
        selected: _selected,
        revealed: _selected != null,
        onSelect: _answer,
        header: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 6, children: [Pill(q.topic), Pill('Level ${q.difficulty}', color: Colors.grey)]),
        ),
      ),
      bottomNavigationBar: _selected == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Readable(
                    child: FilledButton(
                        onPressed: _next,
                        child: Text(_i >= widget.questions.length - 1 ? 'Finish' : 'Next Question'))),
              ),
            ),
    );
  }
}
