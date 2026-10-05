import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import 'daily_question.dart';
import 'practice.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the app shell to another tab (0 Home, 1 Learn, 2 Practice, 3 Progress, 4 Settings).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final progress = context.watch<ProgressStore>();
    final content = context.read<Content>();
    final cs = Theme.of(context).colorScheme;
    final exam = settings.exam;

    final predicted = progress.predictedScore(exam, settings.activeSubjects);
    final target = settings.targetScore;
    final weak = progress.weakestTopics(exam, limit: 3);
    final days = settings.daysUntilTest;
    final plan = settings.name.trim().isEmpty ? 'Welcome back' : 'Hi, ${settings.name.trim()}';

    return Scaffold(
      appBar: AppBar(title: Text(plan)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SegmentedButton<ExamType>(
              showSelectedIcon: false,
              segments: [
                for (final e in ExamType.values) ButtonSegment(value: e, label: Text('${e.label} Prep')),
              ],
              selected: {exam},
              onSelectionChanged: (s) => settings.setExam(s.first),
            ),
            const SizedBox(height: 14),
            if (days != null) ...[
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.event_rounded, color: cs.onPrimaryContainer, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                          days == 0
                              ? 'Your ${exam.label} is today. Good luck!'
                              : '$days day${days == 1 ? '' : 's'} until your ${exam.label}',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Score card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Predicted ${exam.label} score',
                            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        Text(predicted?.toString() ?? '—',
                            style: TextStyle(
                                fontSize: 48, fontWeight: FontWeight.w800, color: cs.primary, height: 1.1)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Target', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      Text('$target', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: predicted == null
                          ? 0
                          : ((predicted - exam.minScore) / (target - exam.minScore)).clamp(0, 1).toDouble(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      predicted == null
                          ? 'Take the diagnostic or answer a few questions to see your estimate.'
                          : predicted >= target
                              ? 'You are at or above your target. Keep it up.'
                              : '${target - predicted} points to go.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Daily goal + streak
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: settings.dailyGoalProgress,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              backgroundColor: cs.surfaceContainerHighest,
                              color: settings.hasMetDailyGoal ? Colors.green : cs.primary,
                            ),
                          ),
                          settings.hasMetDailyGoal
                              ? const Icon(Icons.check_rounded, color: Colors.green, size: 34)
                              : Text('${settings.minutesToday}m',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Text('Daily goal: ${settings.dailyMinutes} min',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 52, color: settings.streak > 0 ? Colors.orange : cs.outline),
                      Text('${settings.streak}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
                      Text('day streak', style: TextStyle(color: cs.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
            ])),
            const SectionHeader('Today'),
            if (!settings.hasTakenDiagnostic) ...[
              NavCard(
                icon: Icons.monitor_heart_outlined,
                color: Colors.orange,
                title: 'Take the diagnostic',
                subtitle: 'Find your baseline ${exam.label} score',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => const DiagnosticIntroScreen())),
              ),
              const SizedBox(height: 10),
            ],
            if (settings.dailyQuestion() != null)
              NavCard(
                icon: Icons.wb_sunny_rounded,
                color: Colors.amber.shade700,
                title: 'Question of the day',
                subtitle: settings.answeredDailyQuestionToday ? 'Answered. Back tomorrow!' : 'One question, two minutes',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => const DailyQuestionScreen())),
              ),
            const SizedBox(height: 10),
            NavCard(
              icon: Icons.quiz_rounded,
              color: cs.primary,
              title: 'Practice questions',
              subtitle: '${formatCount(content.countFor(exam))} ${exam.label} questions',
              onTap: () => onOpenTab(2),
            ),
            if (weak.isNotEmpty) ...[
              const SectionHeader('Focus areas'),
              for (final t in weak) ...[
                Card(
                  child: ListTile(
                    leading: IconBadge(t.subject.icon, color: t.subject.color),
                    title: Text(t.topic, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.subject.displayName} · ${(t.accuracy * 100).round()}% correct'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => PracticeSetupScreen(subject: t.subject))),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ]),
        ),
      ]),
    );
  }
}
