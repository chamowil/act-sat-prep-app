import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/content.dart';
import 'models/exam.dart';
import 'models/subject.dart';

/// Seeds a realistic study history for capturing store screenshots.
///
/// Only runs when launched with `--dart-define=DEMO_DATA=act` (or `sat`). It is
/// compile-time gated, so it is never active in a normal build.
const _demo = String.fromEnvironment('DEMO_DATA');

bool get demoDataRequested => _demo == 'act' || _demo == 'sat';

Future<void> seedDemoData(SharedPreferences p, Content c) async {
  if (!demoDataRequested) return;
  final exam = _demo == 'sat' ? ExamType.sat : ExamType.act;
  await p.clear();
  final now = DateTime.now();
  String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  await p.setString('exam', exam.name);
  await p.setBool('onboarded', true);
  await p.setString('name', 'Alex');
  await p.setInt('targetAct', 30);
  await p.setInt('targetSat', 1400);
  await p.setInt('dailyMinutes', 20);
  await p.setInt('testDate', now.add(const Duration(days: 47)).millisecondsSinceEpoch);
  await p.setBool('isPro', true);
  await p.setStringList('diagnosticDone', ['act', 'sat']);

  final log = <String, int>{key(now): 12};
  for (var i = 1; i <= 6; i++) {
    log[key(now.subtract(Duration(days: i)))] = 25;
  }
  await p.setString('practiceLog', jsonEncode(log));

  // Mock exam history trending upward.
  final ratios = [0.58, 0.67, 0.76];
  final results = <ExamResult>[];
  for (var i = 0; i < ratios.length; i++) {
    results.add(ExamResult(
      id: 'demo$i',
      exam: exam,
      examNumber: i + 1,
      mode: ExamMode.quick,
      date: now.subtract(Duration(days: 30 - i * 12)),
      sections: [
        for (final s in exam.subjects)
          SectionResult(
              s, (ExamMode.quick.count(s) * (ratios[i] + (s.index % 2) * 0.04)).round(), ExamMode.quick.count(s)),
      ],
    ));
  }
  await p.setString('examResults', jsonEncode(results.map((r) => r.toJson()).toList()));

  // Practice history: roughly 70% correct, weaker on a few topics.
  final outcomes = <String, bool>{};
  for (final s in exam.subjects) {
    final qs = c.questionsFor(s);
    for (var i = 0; i < qs.length && i < 70; i++) {
      final weak = qs[i].topic.hashCode % 5 == 0;
      outcomes[qs[i].id] = (i * 7 % 10) < (weak ? 4 : 8);
    }
  }
  await p.setString('practiceOutcomes', jsonEncode(outcomes));

  final tutorials = c.tutorialsForExam(exam).take(6).map((t) => t.id).toList();
  await p.setStringList('completedTutorials', tutorials);

  final cards = <String, dynamic>{};
  for (final card in c.flashcards.where((f) => f.subject.exam == exam).take(40)) {
    cards[card.id] = {
      'e': 2.6,
      'i': 4,
      's': 3,
      'd': now.add(const Duration(days: 3)).millisecondsSinceEpoch,
      'n': true
    };
  }
  await p.setString('cardStates', jsonEncode(cards));
}
