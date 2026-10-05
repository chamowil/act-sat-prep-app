import 'package:act_sat_prep/data/content.dart';
import 'package:act_sat_prep/models/exam.dart';
import 'package:act_sat_prep/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Content content;
  setUpAll(() async => content = await Content.load());

  test('every question is well-formed', () {
    final ids = <String>{};
    for (final q in content.questions) {
      expect(ids.add(q.id), isTrue, reason: 'duplicate id ${q.id}');
      expect(q.choices.length, 4, reason: q.id);
      expect(q.choices.toSet().length, 4, reason: 'duplicate choices in ${q.id}');
      expect(q.correctIndex, inInclusiveRange(0, 3), reason: q.id);
      expect(q.explanation.trim(), isNotEmpty, reason: q.id);
      if (q.passageId != null) {
        expect(content.passages.containsKey(q.passageId), isTrue, reason: '${q.id} passage');
      }
    }
  });

  test('both exams have content for every section', () {
    for (final e in ExamType.values) {
      for (final s in e.subjects) {
        expect(content.questionsFor(s), isNotEmpty, reason: s.name);
      }
      expect(content.tutorialsForExam(e), isNotEmpty);
      expect(content.decksFor(e), isNotEmpty);
    }
  });

  test('every exam mode can be filled from the bank', () {
    for (final e in ExamType.values) {
      for (final s in e.subjects) {
        for (final mode in [ExamMode.quick, ExamMode.full, ExamMode.diagnostic]) {
          final qs = content.examQuestions(s, 0, mode.count(s));
          expect(qs.length, mode.count(s), reason: '${s.name} ${mode.name}');
        }
      }
    }
  });

  test('mock exams for the same section differ', () {
    final a = content.examQuestions(Subject.satmath, 0, 44).map((q) => q.id).toSet();
    final b = content.examQuestions(Subject.satmath, 1, 44).map((q) => q.id).toSet();
    expect(a, isNot(equals(b)));
  });

  test('scoring stays in range', () {
    expect(ExamType.act.sectionScore(0, 40), inInclusiveRange(1, 36));
    expect(ExamType.act.sectionScore(40, 40), 36);
    expect(ExamType.sat.sectionScore(0, 44), 200);
    expect(ExamType.sat.sectionScore(44, 44), 800);
    expect(ExamType.sat.composite([800, 800]), 1600);
    expect(ExamType.sat.composite([200, 200]), 400);
    expect(ExamType.act.composite([30, 32, 28, 30]), 30);
  });
}
