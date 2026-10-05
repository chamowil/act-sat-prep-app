import 'subject.dart';

enum ExamMode { quick, full, diagnostic }

extension ExamModeX on ExamMode {
  String get displayName => switch (this) {
        ExamMode.quick => 'Quick',
        ExamMode.full => 'Full-Length',
        ExamMode.diagnostic => 'Diagnostic',
      };

  int count(Subject s) => switch (this) {
        ExamMode.full => s.fullCount,
        ExamMode.quick => s.quickCount,
        ExamMode.diagnostic => s.diagnosticCount,
      };

  int minutes(Subject s) => switch (this) {
        ExamMode.full => s.fullMinutes,
        ExamMode.quick => s.quickMinutes,
        ExamMode.diagnostic => s.diagnosticMinutes,
      };
}

class SectionResult {
  SectionResult(this.subject, this.correct, this.total);
  final Subject subject;
  final int correct;
  final int total;

  int get scaled => subject.exam.sectionScore(correct, total);

  Map<String, dynamic> toJson() => {'s': subject.id, 'c': correct, 't': total};
  factory SectionResult.fromJson(Map<String, dynamic> j) =>
      SectionResult(SubjectX.fromId(j['s'] as String), j['c'] as int, j['t'] as int);
}

class ExamResult {
  ExamResult({
    required this.id,
    required this.exam,
    required this.examNumber,
    required this.mode,
    required this.date,
    required this.sections,
  });

  final String id;
  final ExamType exam;
  final int examNumber;
  final ExamMode mode;
  final DateTime date;
  final List<SectionResult> sections;

  int get composite => exam.composite(sections.map((s) => s.scaled).toList());
  int get totalCorrect => sections.fold(0, (n, s) => n + s.correct);
  int get totalQuestions => sections.fold(0, (n, s) => n + s.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam': exam.id,
        'n': examNumber,
        'mode': mode.name,
        'date': date.millisecondsSinceEpoch,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: j['id'] as String,
        exam: ExamType.values.firstWhere((e) => e.name == (j['exam'] ?? 'act')),
        examNumber: j['n'] as int,
        mode: ExamMode.values.firstWhere((m) => m.name == j['mode']),
        date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
        sections: (j['sections'] as List)
            .map((e) => SectionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
