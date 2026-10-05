import 'subject.dart';

class Question {
  Question({
    required this.id,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    this.passageId,
    this.stimulus,
  });

  final String id;
  final Subject subject;
  final String? passageId;

  /// A short self-contained text shown above the prompt (SAT Reading & Writing).
  final String? stimulus;
  final String topic;
  final int difficulty;
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        subject: SubjectX.fromId(j['subject'] as String),
        passageId: j['passageId'] as String?,
        stimulus: j['stimulus'] as String?,
        topic: j['topic'] as String,
        difficulty: (j['difficulty'] as num).toInt(),
        prompt: j['prompt'] as String,
        choices: (j['choices'] as List).cast<String>(),
        correctIndex: (j['correctIndex'] as num).toInt(),
        explanation: j['explanation'] as String,
      );
}

class Passage {
  Passage({required this.id, required this.subject, required this.title, required this.text});
  final String id;
  final Subject subject;
  final String title;
  final String text;

  factory Passage.fromJson(Map<String, dynamic> j) => Passage(
        id: j['id'] as String,
        subject: SubjectX.fromId(j['subject'] as String),
        title: j['title'] as String,
        text: j['text'] as String,
      );
}
