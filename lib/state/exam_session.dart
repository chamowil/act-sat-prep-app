import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/content.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/subject.dart';

class ExamSection {
  ExamSection(this.subject, this.questions, this.minutes);
  final Subject subject;
  final List<Question> questions;
  final int minutes;
}

/// A timed, sectioned exam. Time is derived from a wall-clock deadline, so the
/// countdown stays correct if the app is backgrounded.
class ExamSession extends ChangeNotifier {
  ExamSession({
    required this.exam,
    required this.examIndex,
    required this.mode,
    required List<Subject> subjects,
    required Content content,
  })  : sections = [
          for (final s in subjects)
            ExamSection(s, content.examQuestions(s, examIndex, mode.count(s)), mode.minutes(s))
        ],
        _startedAt = DateTime.now() {
    _beginSection();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final ExamType exam;
  final int examIndex;
  final ExamMode mode;
  final List<ExamSection> sections;
  final DateTime _startedAt;

  int sectionIndex = 0;
  int questionIndex = 0;
  bool isFinished = false;
  final Map<String, int> answers = {};
  final Set<String> flagged = {};
  late DateTime _deadline;
  int secondsRemaining = 0;
  Timer? _timer;

  int get examNumber => examIndex + 1;
  int get elapsedSeconds => DateTime.now().difference(_startedAt).inSeconds;

  ExamSection get section => sections[sectionIndex];
  Question? get question {
    final qs = section.questions;
    return questionIndex >= 0 && questionIndex < qs.length ? qs[questionIndex] : null;
  }

  bool get isLastSection => sectionIndex == sections.length - 1;
  bool get isLastQuestion => questionIndex >= section.questions.length - 1;
  int get answeredInSection => section.questions.where((q) => answers.containsKey(q.id)).length;
  int? get selectedChoice => question == null ? null : answers[question!.id];

  void _beginSection() {
    _deadline = DateTime.now().add(Duration(minutes: section.minutes));
    secondsRemaining = section.minutes * 60;
  }

  void _tick() {
    if (isFinished) return;
    final left = _deadline.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      endSection();
    } else {
      secondsRemaining = left;
      notifyListeners();
    }
  }

  void select(int choice) {
    final q = question;
    if (q == null) return;
    answers[q.id] = choice;
    notifyListeners();
  }

  void toggleFlag() {
    final q = question;
    if (q == null) return;
    flagged.contains(q.id) ? flagged.remove(q.id) : flagged.add(q.id);
    notifyListeners();
  }

  void next() {
    if (!isLastQuestion) {
      questionIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (questionIndex > 0) {
      questionIndex--;
      notifyListeners();
    }
  }

  void jump(int i) {
    if (i >= 0 && i < section.questions.length) {
      questionIndex = i;
      notifyListeners();
    }
  }

  /// Ends the current section; advances to the next or finishes the exam.
  void endSection() {
    if (isLastSection) {
      finish();
    } else {
      sectionIndex++;
      questionIndex = 0;
      _beginSection();
      notifyListeners();
    }
  }

  void finish() {
    if (isFinished) return;
    isFinished = true;
    _timer?.cancel();
    notifyListeners();
  }

  ExamResult result() => ExamResult(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        exam: exam,
        examNumber: examNumber,
        mode: mode,
        date: DateTime.now(),
        sections: [
          for (final s in sections)
            SectionResult(s.subject,
                s.questions.where((q) => answers[q.id] == q.correctIndex).length, s.questions.length)
        ],
      );

  String get timeString {
    final m = secondsRemaining ~/ 60, s = secondsRemaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
