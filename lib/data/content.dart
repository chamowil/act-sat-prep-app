import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/question.dart';
import '../models/study.dart';
import '../models/subject.dart';

/// All bundled study content, decoded once at launch.
///
/// Content ships as plain JSON in `assets/<exam>/...`. To add material, append
/// objects to a file listed below (or add a new file to the list) and rebuild.
class Content {
  Content._();

  static const _questionFiles = [
    'assets/act/questions/english_questions.json',
    'assets/act/questions/english_questions_2.json',
    'assets/act/questions/math_questions.json',
    'assets/act/questions/math_questions_2.json',
    'assets/act/questions/reading_questions.json',
    'assets/act/questions/reading_questions_2.json',
    'assets/act/questions/science_questions.json',
    'assets/act/questions/science_questions_2.json',
    'assets/sat/questions/sat_rw_questions.json',
    'assets/sat/questions/sat_math_questions.json',
  ];
  static const _passageFiles = [
    'assets/act/questions/english_passages.json',
    'assets/act/questions/english_passages_2.json',
    'assets/act/questions/reading_passages.json',
    'assets/act/questions/reading_passages_2.json',
    'assets/act/questions/science_passages.json',
    'assets/act/questions/science_passages_2.json',
  ];
  static const _tutorialFiles = [
    'assets/act/tutorials/math_tutorials.json',
    'assets/act/tutorials/science_tutorials.json',
    'assets/sat/tutorials/sat_tutorials.json',
  ];

  final List<Question> questions = [];
  final Map<String, Passage> passages = {};
  final Map<Subject, List<Question>> _bySubject = {};
  final List<Tutorial> tutorials = [];
  final List<Flashcard> flashcards = [];
  final List<ReferenceEntry> reference = [];
  final List<WritingPrompt> prompts = [];
  final List<SampleEssay> samples = [];
  final List<WritingGuide> guides = [];

  static Future<List<dynamic>> _json(String path) async =>
      jsonDecode(await rootBundle.loadString(path)) as List<dynamic>;

  static Future<Content> load() async {
    final c = Content._();
    for (final f in _questionFiles) {
      for (final j in await _json(f)) {
        c.questions.add(Question.fromJson(j as Map<String, dynamic>));
      }
    }
    for (final f in _passageFiles) {
      for (final j in await _json(f)) {
        final p = Passage.fromJson(j as Map<String, dynamic>);
        c.passages[p.id] = p;
      }
    }
    for (final f in _tutorialFiles) {
      for (final j in await _json(f)) {
        c.tutorials.add(Tutorial.fromJson(j as Map<String, dynamic>));
      }
    }
    for (final f in const [
      'assets/act/study/flashcards.json',
      'assets/sat/study/flashcards.json'
    ]) {
      for (final j in await _json(f)) {
        c.flashcards.add(Flashcard.fromJson(j as Map<String, dynamic>));
      }
    }
    for (final j in await _json('assets/act/study/reference.json')) {
      c.reference.add(ReferenceEntry.fromJson(j as Map<String, dynamic>));
    }
    for (final j in await _json('assets/act/writing/writing_prompts.json')) {
      c.prompts.add(WritingPrompt.fromJson(j as Map<String, dynamic>));
    }
    for (final j in await _json('assets/act/writing/writing_samples.json')) {
      c.samples.add(SampleEssay.fromJson(j as Map<String, dynamic>));
    }
    for (final j in await _json('assets/act/writing/writing_guides.json')) {
      c.guides.add(WritingGuide.fromJson(j as Map<String, dynamic>));
    }
    for (final q in c.questions) {
      c._bySubject.putIfAbsent(q.subject, () => []).add(q);
    }
    return c;
  }

  List<Question> questionsFor(Subject s) => _bySubject[s] ?? const [];

  int countFor(ExamType exam) =>
      exam.subjects.fold(0, (n, s) => n + questionsFor(s).length);

  List<String> topicsFor(Subject s) =>
      (questionsFor(s).map((q) => q.topic).toSet().toList()..sort());

  Passage? passageFor(Question q) => q.passageId == null ? null : passages[q.passageId];

  List<Tutorial> tutorialsFor(Subject s) => tutorials.where((t) => t.subject == s).toList();

  List<String> tutorialCategories(Subject s) {
    final order = <String>[];
    for (final t in tutorialsFor(s)) {
      if (!order.contains(t.category)) order.add(t.category);
    }
    return order;
  }

  List<Tutorial> tutorialsForExam(ExamType e) =>
      tutorials.where((t) => t.subject.exam == e).toList();

  List<FlashcardDeck> decksFor(ExamType e) {
    final order = <String>[];
    final grouped = <String, List<Flashcard>>{};
    for (final c in flashcards.where((c) => c.subject.exam == e)) {
      if (!grouped.containsKey(c.deck)) order.add(c.deck);
      grouped.putIfAbsent(c.deck, () => []).add(c);
    }
    return [for (final n in order) FlashcardDeck(n, grouped[n]!.first.subject, grouped[n]!)];
  }

  List<String> get referenceCategories {
    final order = <String>[];
    for (final r in reference) {
      if (!order.contains(r.category)) order.add(r.category);
    }
    return order;
  }

  List<ReferenceEntry> searchReference(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return const [];
    return reference
        .where((r) =>
            r.title.toLowerCase().contains(t) ||
            r.summary.toLowerCase().contains(t) ||
            r.body.toLowerCase().contains(t) ||
            r.category.toLowerCase().contains(t))
        .toList();
  }

  WritingPrompt? prompt(String id) => prompts.where((p) => p.id == id).firstOrNull;

  List<SampleEssay> samplesFor(String promptId) =>
      samples.where((s) => s.promptId == promptId).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

  /// Deterministic slice of a subject's questions for one mock exam. Rotates
  /// through the bank so consecutive exams overlap as little as possible, and
  /// walks whole passages for passage-based sections so sets stay coherent.
  List<Question> examQuestions(Subject subject, int examIndex, int count) {
    final pool = questionsFor(subject);
    if (pool.isEmpty) return const [];
    if (!subject.usesPassages) {
      final start = (examIndex * count) % pool.length;
      return [for (var i = 0; i < count && i < pool.length; i++) pool[(start + i) % pool.length]];
    }
    final byPassage = <String, List<Question>>{};
    final order = <String>[];
    for (final q in pool) {
      final key = q.passageId ?? q.id;
      if (!byPassage.containsKey(key)) order.add(key);
      byPassage.putIfAbsent(key, () => []).add(q);
    }
    final result = <Question>[];
    var idx = examIndex % order.length;
    var guard = 0;
    while (result.length < count && guard++ < order.length * 2) {
      final group = byPassage[order[idx]]!;
      result.addAll(group.take(count - result.length));
      idx = (idx + 1) % order.length;
    }
    return result;
  }
}
