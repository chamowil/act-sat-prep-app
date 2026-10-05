import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../models/study.dart';
import '../models/exam.dart';
import '../models/subject.dart';

class TopicStat {
  TopicStat(this.subject, this.topic, this.attempted, this.correct);
  final Subject subject;
  final String topic;
  final int attempted;
  final int correct;
  double get accuracy => attempted > 0 ? correct / attempted : 0;
}

/// Exam results, practice history, tutorial completion — all stored locally.
class ProgressStore extends ChangeNotifier {
  ProgressStore(this._p, this._content) {
    try {
      final r = _p.getString('examResults');
      if (r != null) {
        _results = (jsonDecode(r) as List)
            .map((e) => ExamResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final o = _p.getString('practiceOutcomes');
      if (o != null) {
        _outcomes = (jsonDecode(o) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as bool));
      }
    } catch (_) {
      // Corrupt data should never block launch; start fresh.
    }
    _completed = (_p.getStringList('completedTutorials') ?? const []).toSet();
  }

  final SharedPreferences _p;
  final Content _content;
  List<ExamResult> _results = [];
  Map<String, bool> _outcomes = {};
  Set<String> _completed = {};

  List<ExamResult> resultsFor(ExamType e) => _results.where((r) => r.exam == e).toList();

  void saveResult(ExamResult r) {
    _results.add(r);
    _p.setString('examResults', jsonEncode(_results.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void recordPractice(String questionId, bool correct) {
    _outcomes[questionId] = correct;
    _p.setString('practiceOutcomes', jsonEncode(_outcomes));
    notifyListeners();
  }

  bool? outcomeFor(String id) => _outcomes[id];

  // ---- Tutorials ----------------------------------------------------------
  bool isTutorialCompleted(String id) => _completed.contains(id);

  void toggleTutorial(String id) {
    _completed.contains(id) ? _completed.remove(id) : _completed.add(id);
    _p.setStringList('completedTutorials', _completed.toList());
    notifyListeners();
  }

  int completedTutorials(ExamType e) =>
      _content.tutorialsForExam(e).where((t) => _completed.contains(t.id)).length;

  // ---- Derived stats ------------------------------------------------------
  int? bestComposite(ExamType e) {
    final r = resultsFor(e);
    return r.isEmpty ? null : r.map((x) => x.composite).reduce(max);
  }

  int? latestComposite(ExamType e) {
    final r = resultsFor(e)..sort((a, b) => a.date.compareTo(b.date));
    return r.isEmpty ? null : r.last.composite;
  }

  ({int attempted, int correct}) practiceStats(Subject s) {
    var a = 0, c = 0;
    for (final q in _content.questionsFor(s)) {
      final o = _outcomes[q.id];
      if (o != null) {
        a++;
        if (o) c++;
      }
    }
    return (attempted: a, correct: c);
  }

  int totalAttempted(ExamType e) =>
      e.subjects.fold(0, (n, s) => n + practiceStats(s).attempted);
  int totalCorrect(ExamType e) => e.subjects.fold(0, (n, s) => n + practiceStats(s).correct);

  List<TopicStat> topicStats(Subject s) {
    final attempted = <String, int>{};
    final correct = <String, int>{};
    for (final q in _content.questionsFor(s)) {
      attempted.putIfAbsent(q.topic, () => 0);
      correct.putIfAbsent(q.topic, () => 0);
      final o = _outcomes[q.id];
      if (o != null) {
        attempted[q.topic] = attempted[q.topic]! + 1;
        if (o) correct[q.topic] = correct[q.topic]! + 1;
      }
    }
    final keys = attempted.keys.toList()..sort();
    return [for (final k in keys) TopicStat(s, k, attempted[k]!, correct[k]!)];
  }

  List<TopicStat> weakestTopics(ExamType e, {int limit = 5, int minimumAttempts = 3}) {
    final all = e.subjects
        .expand(topicStats)
        .where((t) => t.attempted >= minimumAttempts && t.accuracy < 0.8)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return all.take(limit).toList();
  }

  /// Estimated score blending recent mock exams (75%) with practice accuracy (25%).
  int? predictedScore(ExamType e, List<Subject> active) {
    final exams = resultsFor(e)..sort((a, b) => a.date.compareTo(b.date));
    final examScores = exams.reversed.take(3).map((r) {
      final secs = r.sections.where((s) => active.contains(s.subject));
      return e.composite(secs.map((s) => s.scaled).toList());
    }).toList();

    final practiceScaled = <int>[];
    for (final s in active) {
      final st = practiceStats(s);
      if (st.attempted >= 5) practiceScaled.add(e.sectionScore(st.correct, st.attempted));
    }
    final practiceComposite = practiceScaled.isEmpty ? null : e.composite(practiceScaled);
    final examAvg =
        examScores.isEmpty ? null : examScores.reduce((a, b) => a + b) / examScores.length;

    double? v;
    if (examAvg != null && practiceComposite != null) {
      v = examAvg * 0.75 + practiceComposite * 0.25;
    } else {
      v = examAvg ?? practiceComposite?.toDouble();
    }
    if (v == null) return null;
    return e == ExamType.act ? v.round() : ((v / 10).round() * 10);
  }

  Future<void> resetAll() async {
    _results = [];
    _outcomes = {};
    _completed = {};
    await _p.remove('examResults');
    await _p.remove('practiceOutcomes');
    await _p.remove('completedTutorials');
    notifyListeners();
  }
}

/// SM-2-style spaced repetition for flashcards.
enum RecallGrade { forgot, hard, good, easy }

class CardState {
  CardState({this.ease = 2.5, this.interval = 0, this.streak = 0, this.due = 0, this.seen = false});
  double ease;
  int interval;
  int streak;

  /// Milliseconds since epoch; 0 means due immediately.
  int due;
  bool seen;

  Map<String, dynamic> toJson() =>
      {'e': ease, 'i': interval, 's': streak, 'd': due, 'n': seen};
  factory CardState.fromJson(Map<String, dynamic> j) => CardState(
        ease: (j['e'] as num).toDouble(),
        interval: j['i'] as int,
        streak: j['s'] as int,
        due: j['d'] as int,
        seen: j['n'] as bool,
      );
}

class FlashcardScheduler extends ChangeNotifier {
  FlashcardScheduler(this._p, this._content) {
    try {
      final raw = _p.getString('cardStates');
      if (raw != null) {
        _states = (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, CardState.fromJson(v as Map<String, dynamic>)));
      }
    } catch (_) {}
  }

  final SharedPreferences _p;
  final Content _content;
  Map<String, CardState> _states = {};

  CardState stateOf(String id) => _states[id] ?? CardState();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  List<Flashcard> dueCards(FlashcardDeck deck, {int limit = 20}) {
    final now = _now();
    final due = deck.cards.where((c) => stateOf(c.id).due <= now).toList();
    final unseen = due.where((c) => !stateOf(c.id).seen).toList();
    final review = due.where((c) => stateOf(c.id).seen).toList()
      ..sort((a, b) => stateOf(a.id).due.compareTo(stateOf(b.id).due));
    return [...unseen, ...review].take(limit).toList();
  }

  int dueCount(FlashcardDeck deck) {
    final now = _now();
    return deck.cards.where((c) => stateOf(c.id).due <= now).length;
  }

  int learnedCount(FlashcardDeck deck) =>
      deck.cards.where((c) => stateOf(c.id).streak >= 2).length;

  int totalDue(ExamType e) => _content.decksFor(e).fold(0, (n, d) => n + dueCount(d));
  int totalLearned(ExamType e) => _content.decksFor(e).fold(0, (n, d) => n + learnedCount(d));

  void record(String cardId, RecallGrade grade) {
    final s = stateOf(cardId);
    s.seen = true;
    switch (grade) {
      case RecallGrade.forgot:
        s.streak = 0;
        s.interval = 0;
        s.ease = max(1.3, s.ease - 0.2);
      case RecallGrade.hard:
        s.streak += 1;
        s.interval = max(1, (max(s.interval, 1) * 1.2).floor());
        s.ease = max(1.3, s.ease - 0.15);
      case RecallGrade.good:
        s.streak += 1;
        s.interval = s.interval == 0 ? 1 : (s.interval * s.ease).round();
      case RecallGrade.easy:
        s.streak += 1;
        s.interval = s.interval == 0 ? 3 : (s.interval * s.ease * 1.3).round();
        s.ease = min(3.0, s.ease + 0.15);
    }
    s.interval = min(s.interval, 180);
    // A forgotten card comes back in this same session rather than tomorrow.
    s.due = s.interval == 0
        ? _now() + 60 * 1000
        : DateTime.now().add(Duration(days: s.interval)).millisecondsSinceEpoch;
    _states[cardId] = s;
    _p.setString('cardStates', jsonEncode(_states.map((k, v) => MapEntry(k, v.toJson()))));
    notifyListeners();
  }

  Future<void> resetAll() async {
    _states = {};
    await _p.remove('cardStates');
    notifyListeners();
  }
}
