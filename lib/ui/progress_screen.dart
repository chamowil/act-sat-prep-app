import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import 'theme.dart';

class Badge {
  Badge(this.title, this.detail, this.icon, this.color, int value, int goal)
      : earned = value >= goal,
        progress = goal > 0 ? min(1.0, value / goal) : 0.0;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool earned;
  final double progress;
}

List<Badge> computeBadges(
    ExamType exam, AppSettings settings, ProgressStore progress, FlashcardScheduler cards, Content content) {
  final attempted = progress.totalAttempted(exam);
  final correct = progress.totalCorrect(exam);
  final exams = progress.resultsFor(exam).length;
  final best = progress.bestComposite(exam) ?? 0;
  final streak = settings.streak;
  final learned = cards.totalLearned(exam);
  final tutorialsDone = progress.completedTutorials(exam);
  final tutorialTotal = content.tutorialsForExam(exam).length;
  final mid = exam == ExamType.act ? 24 : 1200;
  final high = exam == ExamType.act ? 30 : 1400;
  return [
    Badge('First Steps', 'Answer your first question', Icons.directions_walk, Colors.blue, attempted, 1),
    Badge('Half Century', 'Answer 50 questions', Icons.filter_5, Colors.blue, attempted, 50),
    Badge('Serious Student', 'Answer 250 questions', Icons.local_library, Colors.indigo, attempted, 250),
    Badge('Sharpshooter', 'Get 100 questions right', Icons.gps_fixed, Colors.green, correct, 100),
    Badge('Warming Up', 'Hit your daily goal 3 days running', Icons.local_fire_department_outlined, Colors.orange, streak, 3),
    Badge('Week Strong', 'Hit your daily goal 7 days running', Icons.local_fire_department, Colors.orange, streak, 7),
    Badge('Unstoppable', 'Hit your daily goal 30 days running', Icons.workspace_premium, Colors.amber, streak, 30),
    Badge('Test Day Rehearsal', 'Finish your first mock exam', Icons.flag, Colors.purple, exams, 1),
    Badge('Seasoned', 'Finish 5 mock exams', Icons.verified, Colors.purple, exams, 5),
    Badge('Above Average', 'Score $mid or better on a mock exam', Icons.trending_up, Colors.teal, best, mid),
    Badge('Top Tier', 'Score $high or better on a mock exam', Icons.star, Colors.amber, best, high),
    Badge('Card Shark', 'Learn 50 flashcards', Icons.style, Colors.pink, learned, 50),
    Badge('Well Read', 'Complete 5 tutorials', Icons.menu_book, Colors.cyan, tutorialsDone, 5),
    Badge('Completionist', 'Complete every tutorial', Icons.school, Colors.indigo, tutorialsDone, max(1, tutorialTotal)),
    Badge('Goal Reached', 'Reach your target score of ${settings.targetScore}', Icons.emoji_events, Colors.amber, best,
        settings.targetScore),
  ];
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final progress = context.watch<ProgressStore>();
    final cards = context.watch<FlashcardScheduler>();
    final content = context.read<Content>();
    final cs = Theme.of(context).colorScheme;
    final exam = settings.exam;
    final results = progress.resultsFor(exam)..sort((a, b) => a.date.compareTo(b.date));
    final badges = computeBadges(exam, settings, progress, cards, content);
    final earned = badges.where((b) => b.earned).length;

    return Scaffold(
      appBar: AppBar(title: Text('${exam.label} Progress')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Stat('Questions', '${progress.totalAttempted(exam)}', Icons.quiz_rounded, cs.primary),
              const SizedBox(width: 10),
              _Stat(
                  'Accuracy',
                  progress.totalAttempted(exam) == 0
                      ? '—'
                      : '${(progress.totalCorrect(exam) * 100 / progress.totalAttempted(exam)).round()}%',
                  Icons.gps_fixed,
                  Colors.green),
              const SizedBox(width: 10),
              _Stat('Best score', progress.bestComposite(exam)?.toString() ?? '—', Icons.emoji_events, Colors.amber.shade700),
            ]),
            const SectionHeader('Score trend'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: results.length < 2
                    ? Text(
                        results.isEmpty
                            ? 'Complete a mock exam or the diagnostic to start your score trend.'
                            : 'Complete one more exam to see your trend.',
                        style: TextStyle(color: cs.onSurfaceVariant))
                    : SizedBox(
                        height: 150,
                        child: CustomPaint(
                            size: Size.infinite,
                            painter: _TrendPainter(
                                results.map((r) => r.composite).toList(), exam, cs.primary, cs.outlineVariant)),
                      ),
              ),
            ),
            const SectionHeader('By subject'),
            for (final s in exam.subjects) ...[
              Builder(builder: (context) {
                final st = progress.practiceStats(s);
                final acc = st.attempted == 0 ? 0.0 : st.correct / st.attempted;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      Row(children: [
                        IconBadge(s.icon, color: s.color, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(s.displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        Text(st.attempted == 0 ? 'Not started' : '${(acc * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: acc, minHeight: 7, color: s.color),
                      ),
                      const SizedBox(height: 6),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${st.correct} of ${st.attempted} correct',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            const SectionHeader('Topic heatmap'),
            for (final s in exam.subjects) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Text(s.displayName,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in progress.topicStats(s)) _TopicChip(t),
              ]),
              const SizedBox(height: 10),
            ],
            if (results.isNotEmpty) ...[
              const SectionHeader('Exam history'),
              for (final r in results.reversed.take(10)) ...[
                Card(
                  child: ListTile(
                    leading: IconBadge(Icons.assignment_rounded, color: Colors.purple),
                    title: Text(r.mode == ExamMode.diagnostic ? 'Diagnostic' : 'Mock Exam ${r.examNumber} · ${r.mode.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${r.date.month}/${r.date.day}/${r.date.year} · ${r.totalCorrect}/${r.totalQuestions} correct'),
                    trailing: Text('${r.composite}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            SectionHeader('Badges · $earned of ${badges.length}'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [for (final b in badges) _BadgeTile(b)],
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
}

class _TopicChip extends StatelessWidget {
  const _TopicChip(this.stat);
  final TopicStat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color c = stat.attempted == 0
        ? cs.outline
        : stat.accuracy >= 0.8
            ? Colors.green
            : stat.accuracy >= 0.5
                ? Colors.orange
                : Colors.red;
    return Semantics(
      label: '${stat.topic}, ${stat.attempted == 0 ? 'not attempted' : '${(stat.accuracy * 100).round()} percent'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withValues(alpha: 0.4))),
        child: Text(
            stat.attempted == 0 ? stat.topic : '${stat.topic} · ${(stat.accuracy * 100).round()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.b);
  final Badge b;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '${b.title}. ${b.detail}. ${b.earned ? 'Earned' : 'Not yet earned'}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Opacity(
            opacity: b.earned ? 1 : 0.5,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconBadge(b.icon, color: b.earned ? b.color : cs.outline, size: 44),
              const SizedBox(height: 6),
              Text(b.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (!b.earned)
                LinearProgressIndicator(value: b.progress, minHeight: 3)
              else
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.exam, this.line, this.grid);
  final List<int> values;
  final ExamType exam;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(min).toDouble(), hi = values.reduce(max).toDouble();
    final pad = max(exam == ExamType.act ? 2.0 : 40.0, (hi - lo) * 0.2);
    final minY = lo - pad, maxY = hi + pad;
    Offset pt(int i) => Offset(
          size.width * (values.length == 1 ? 0.5 : i / (values.length - 1)),
          size.height * (1 - (values[i] - minY) / (maxY - minY)),
        );
    final gp = Paint()..color = grid..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(pt(i), 5, Paint()..color = line);
      final tp = TextPainter(
          text: TextSpan(text: '${values[i]}', style: TextStyle(fontSize: 11, color: line, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, pt(i) + Offset(-tp.width / 2, -20));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}
