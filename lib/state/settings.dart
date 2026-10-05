import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../models/question.dart';
import '../models/subject.dart';

/// Study goals and preferences, collected in onboarding and editable in
/// Settings. Backed by SharedPreferences, loaded before the first frame.
class AppSettings extends ChangeNotifier {
  AppSettings(this._p, this._content) {
    _exam = ExamType.values.firstWhere((e) => e.name == _p.getString('exam'),
        orElse: () => ExamType.act);
    _onboarded = _p.getBool('onboarded') ?? false;
    _name = _p.getString('name') ?? '';
    _targetAct = _p.getInt('targetAct') ?? 30;
    _targetSat = _p.getInt('targetSat') ?? 1400;
    _dailyMinutes = _p.getInt('dailyMinutes') ?? 20;
    final td = _p.getInt('testDate');
    _testDate = td == null ? null : DateTime.fromMillisecondsSinceEpoch(td);
    _includesScience = _p.getBool('includesScience') ?? true;
    _diagnosticDone = (_p.getStringList('diagnosticDone') ?? const []).toSet();
    final dq = _p.getInt('dailyQuestionDate');
    _dailyQuestionDate = dq == null ? null : DateTime.fromMillisecondsSinceEpoch(dq);
    final raw = _p.getString('practiceLog');
    if (raw != null) {
      try {
        _log = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }
  }

  final SharedPreferences _p;
  final Content _content;

  static const dailyMinuteOptions = [10, 15, 20, 30, 45, 60];

  late ExamType _exam;
  late bool _onboarded;
  late String _name;
  late int _targetAct;
  late int _targetSat;
  late int _dailyMinutes;
  DateTime? _testDate;
  late bool _includesScience;
  late Set<String> _diagnosticDone;
  DateTime? _dailyQuestionDate;
  Map<String, int> _log = {};

  ExamType get exam => _exam;
  bool get onboarded => _onboarded;
  String get name => _name;
  int get dailyMinutes => _dailyMinutes;
  DateTime? get testDate => _testDate;
  bool get includesScience => _includesScience;

  int get targetScore => _exam == ExamType.act ? _targetAct : _targetSat;

  bool get hasTakenDiagnostic => _diagnosticDone.contains(_exam.id);

  List<Subject> get activeSubjects => _exam == ExamType.act && !_includesScience
      ? _exam.subjects.where((s) => s != Subject.science).toList()
      : _exam.subjects;

  void setExam(ExamType e) {
    _exam = e;
    _p.setString('exam', e.name);
    notifyListeners();
  }

  void setTarget(int v) {
    final t = v.clamp(_exam.minScore, _exam.maxScore);
    if (_exam == ExamType.act) {
      _targetAct = t;
      _p.setInt('targetAct', t);
    } else {
      _targetSat = t;
      _p.setInt('targetSat', t);
    }
    notifyListeners();
  }

  void setName(String v) {
    _name = v;
    _p.setString('name', v);
    notifyListeners();
  }

  void setDailyMinutes(int v) {
    _dailyMinutes = v;
    _p.setInt('dailyMinutes', v);
    notifyListeners();
  }

  void setTestDate(DateTime? d) {
    _testDate = d;
    d == null ? _p.remove('testDate') : _p.setInt('testDate', d.millisecondsSinceEpoch);
    notifyListeners();
  }

  void setIncludesScience(bool v) {
    _includesScience = v;
    _p.setBool('includesScience', v);
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    _p.setBool('onboarded', true);
    notifyListeners();
  }

  void markDiagnosticDone() {
    _diagnosticDone.add(_exam.id);
    _p.setStringList('diagnosticDone', _diagnosticDone.toList());
    notifyListeners();
  }

  // ---- Daily goal tracking ------------------------------------------------

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _minutesOn(DateTime d) => _log[_key(d)] ?? 0;

  int get minutesToday => _minutesOn(DateTime.now());
  double get dailyGoalProgress =>
      _dailyMinutes <= 0 ? 0 : (minutesToday / _dailyMinutes).clamp(0, 1).toDouble();
  bool get hasMetDailyGoal => minutesToday >= _dailyMinutes;

  void logPractice(int seconds) {
    if (seconds <= 0) return;
    final minutes = (seconds / 60).round().clamp(1, 100000);
    final k = _key(DateTime.now());
    _log[k] = (_log[k] ?? 0) + minutes;
    // Keep the log bounded: ~120 days is plenty for streaks.
    if (_log.length > 140) {
      final keys = _log.keys.toList()..sort();
      for (final old in keys.take(_log.length - 120)) {
        _log.remove(old);
      }
    }
    _p.setString('practiceLog', jsonEncode(_log));
    notifyListeners();
  }

  /// Consecutive days (ending today or yesterday) that met the daily goal.
  int get streak {
    var day = _day(DateTime.now());
    if (_minutesOn(day) < _dailyMinutes) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (_minutesOn(day) >= _dailyMinutes && count < 400) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  int? get daysUntilTest {
    final t = _testDate;
    if (t == null) return null;
    final d = _day(t).difference(_day(DateTime.now())).inDays;
    return d >= 0 ? d : null;
  }

  bool get answeredDailyQuestionToday {
    final d = _dailyQuestionDate;
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  void markDailyQuestionAnswered() {
    _dailyQuestionDate = DateTime.now();
    _p.setInt('dailyQuestionDate', _dailyQuestionDate!.millisecondsSinceEpoch);
    notifyListeners();
  }

  /// A stable "question of the day": same all day, new tomorrow.
  Question? dailyQuestion() {
    final pool = activeSubjects.expand(_content.questionsFor).toList();
    if (pool.isEmpty) return null;
    final now = DateTime.now();
    final day = DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 86400000;
    return pool[day % pool.length];
  }

  Future<void> resetAll() async {
    await _p.clear();
    _exam = ExamType.act;
    _onboarded = false;
    _name = '';
    _targetAct = 30;
    _targetSat = 1400;
    _dailyMinutes = 20;
    _testDate = null;
    _includesScience = true;
    _diagnosticDone = {};
    _dailyQuestionDate = null;
    _log = {};
    notifyListeners();
  }
}
