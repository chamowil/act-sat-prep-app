import 'package:flutter/material.dart';

enum ExamType { act, sat }

enum Subject { english, math, reading, science, satrw, satmath }

extension ExamTypeX on ExamType {
  String get label => this == ExamType.act ? 'ACT' : 'SAT';
  String get id => name;

  int get minScore => this == ExamType.act ? 1 : 400;
  int get maxScore => this == ExamType.act ? 36 : 1600;
  int get defaultTarget => this == ExamType.act ? 30 : 1400;
  int get targetStep => this == ExamType.act ? 1 : 10;
  int get mockExamCount => this == ExamType.act ? 15 : 6;

  /// Every section of this exam, in test order.
  List<Subject> get subjects => this == ExamType.act
      ? const [Subject.english, Subject.math, Subject.reading, Subject.science]
      : const [Subject.satrw, Subject.satmath];

  /// Subjects that ship tutorials.
  List<Subject> get tutorialSubjects => this == ExamType.act
      ? const [Subject.math, Subject.science]
      : const [Subject.satrw, Subject.satmath];

  bool get hasWriting => this == ExamType.act;

  String get scoreLabel => this == ExamType.act ? 'out of 36' : 'out of 1600';

  /// Approximate percent-correct → section score.
  int sectionScore(int correct, int total) {
    if (total <= 0) return this == ExamType.act ? 1 : 200;
    final pct = correct / total;
    if (this == ExamType.act) {
      final scaled = 1.0 + pct * 35.0;
      final adjusted = pct >= 0.9 ? (scaled + 1.0).clamp(1.0, 36.0) : scaled;
      return adjusted.round().clamp(1, 36);
    }
    // SAT sections are 200–800 in steps of 10.
    return (200 + (pct * 60).round() * 10).clamp(200, 800);
  }

  /// ACT composite averages sections; SAT total adds the two sections.
  int composite(List<int> sectionScores) {
    if (sectionScores.isEmpty) return minScore;
    final sum = sectionScores.reduce((a, b) => a + b);
    if (this == ExamType.act) {
      return (sum / sectionScores.length).round().clamp(1, 36);
    }
    final total = (((sum / sectionScores.length) * 2) / 10).round() * 10;
    return total.clamp(400, 1600);
  }
}

extension SubjectX on Subject {
  String get id => name;

  static Subject fromId(String id) =>
      Subject.values.firstWhere((s) => s.name == id, orElse: () => Subject.english);

  ExamType get exam =>
      (this == Subject.satrw || this == Subject.satmath) ? ExamType.sat : ExamType.act;

  String get displayName => switch (this) {
        Subject.english => 'English',
        Subject.math => 'Math',
        Subject.reading => 'Reading',
        Subject.science => 'Science',
        Subject.satrw => 'Reading & Writing',
        Subject.satmath => 'Math',
      };

  IconData get icon => switch (this) {
        Subject.english => Icons.menu_book_rounded,
        Subject.math || Subject.satmath => Icons.functions_rounded,
        Subject.reading => Icons.auto_stories_rounded,
        Subject.science => Icons.science_rounded,
        Subject.satrw => Icons.edit_note_rounded,
      };

  Color get color => switch (this) {
        Subject.english => const Color(0xFF3B6FE0),
        Subject.math || Subject.satmath => const Color(0xFFE0703B),
        Subject.reading => const Color(0xFF8A4FE0),
        Subject.science => const Color(0xFF2FA37A),
        Subject.satrw => const Color(0xFF3B6FE0),
      };

  /// True when questions belong to shared passages that must stay together.
  bool get usesPassages =>
      this == Subject.english || this == Subject.reading || this == Subject.science;

  int get fullCount => switch (this) {
        Subject.english => 50,
        Subject.math => 45,
        Subject.reading => 36,
        Subject.science => 40,
        Subject.satrw => 54,
        Subject.satmath => 44,
      };

  int get fullMinutes => switch (this) {
        Subject.english => 35,
        Subject.math => 50,
        Subject.reading => 40,
        Subject.science => 40,
        Subject.satrw => 64,
        Subject.satmath => 70,
      };

  int get quickCount => switch (this) {
        Subject.english => 15,
        Subject.math => 12,
        Subject.reading => 10,
        Subject.science => 10,
        Subject.satrw => 14,
        Subject.satmath => 11,
      };

  int get quickMinutes => switch (this) {
        Subject.english => 10,
        Subject.math => 13,
        Subject.reading => 11,
        Subject.science => 10,
        Subject.satrw => 16,
        Subject.satmath => 18,
      };

  int get diagnosticCount => switch (this) {
        Subject.english => 10,
        Subject.math => 10,
        Subject.reading => 8,
        Subject.science => 8,
        Subject.satrw => 10,
        Subject.satmath => 8,
      };

  int get diagnosticMinutes => switch (this) {
        Subject.english => 7,
        Subject.math => 11,
        Subject.reading => 9,
        Subject.science => 8,
        Subject.satrw => 12,
        Subject.satmath => 12,
      };
}
