import 'subject.dart';

class TutorialSection {
  TutorialSection(this.heading, this.body);
  final String heading;
  final String body;
  factory TutorialSection.fromJson(Map<String, dynamic> j) =>
      TutorialSection(j['heading'] as String, j['body'] as String);
}

class WorkedExample {
  WorkedExample(this.problem, this.steps, this.answer);
  final String problem;
  final List<String> steps;
  final String answer;
  factory WorkedExample.fromJson(Map<String, dynamic> j) => WorkedExample(
      j['problem'] as String, (j['steps'] as List).cast<String>(), j['answer'] as String);
}

class Tutorial {
  Tutorial.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        subject = SubjectX.fromId(j['subject'] as String),
        category = j['category'] as String,
        title = j['title'] as String,
        symbolName = (j['symbolName'] as String?) ?? '',
        summary = j['summary'] as String,
        estimatedMinutes = (j['estimatedMinutes'] as num).toInt(),
        sections = (j['sections'] as List)
            .map((e) => TutorialSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        keyFacts = ((j['keyFacts'] as List?) ?? const []).cast<String>(),
        examples = ((j['examples'] as List?) ?? const [])
            .map((e) => WorkedExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        tips = ((j['tips'] as List?) ?? const []).cast<String>();

  final String id;
  final Subject subject;
  final String category;
  final String title;
  final String symbolName;
  final String summary;
  final int estimatedMinutes;
  final List<TutorialSection> sections;
  final List<String> keyFacts;
  final List<WorkedExample> examples;
  final List<String> tips;
}

class Flashcard {
  Flashcard.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        subject = SubjectX.fromId(j['subject'] as String),
        deck = j['deck'] as String,
        front = j['front'] as String,
        back = j['back'] as String,
        hint = (j['hint'] as String?) ?? '';
  final String id;
  final Subject subject;
  final String deck;
  final String front;
  final String back;
  final String hint;
}

class FlashcardDeck {
  FlashcardDeck(this.name, this.subject, this.cards);
  final String name;
  final Subject subject;
  final List<Flashcard> cards;
}

class ReferenceExample {
  ReferenceExample.fromJson(Map<String, dynamic> j)
      : wrong = (j['wrong'] as String?) ?? '',
        right = (j['right'] as String?) ?? '',
        why = (j['why'] as String?) ?? '';
  final String wrong;
  final String right;
  final String why;
}

class ReferenceEntry {
  ReferenceEntry.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        subject = SubjectX.fromId(j['subject'] as String),
        category = j['category'] as String,
        title = j['title'] as String,
        summary = j['summary'] as String,
        body = j['body'] as String,
        examples = ((j['examples'] as List?) ?? const [])
            .map((e) => ReferenceExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        trap = (j['trap'] as String?) ?? '';
  final String id;
  final Subject subject;
  final String category;
  final String title;
  final String summary;
  final String body;
  final List<ReferenceExample> examples;
  final String trap;
}

class WritingPerspective {
  WritingPerspective(this.label, this.text);
  final String label;
  final String text;
}

class WritingPrompt {
  WritingPrompt.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        context = j['context'] as String,
        perspectives = (j['perspectives'] as List)
            .map((e) => WritingPerspective(
                (e as Map<String, dynamic>)['label'] as String, e['text'] as String))
            .toList(),
        task = j['task'] as String;
  final String id;
  final String title;
  final String context;
  final List<WritingPerspective> perspectives;
  final String task;
}

class SampleEssay {
  SampleEssay.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        promptId = j['promptId'] as String,
        score = (j['score'] as num).toInt(),
        label = j['label'] as String,
        essay = j['essay'] as String,
        comments = (j['graderComments'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String));
  final String id;
  final String promptId;
  final int score;
  final String label;
  final String essay;
  final Map<String, String> comments;

  static const commentTitles = {
    'ideasAndAnalysis': 'Ideas & Analysis',
    'developmentAndSupport': 'Development & Support',
    'organization': 'Organization',
    'languageUse': 'Language Use',
  };
}

class WritingGuide {
  WritingGuide.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        summary = j['summary'] as String,
        estimatedMinutes = (j['estimatedMinutes'] as num).toInt(),
        sections = (j['sections'] as List)
            .map((e) => TutorialSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        checklist = ((j['checklist'] as List?) ?? const []).cast<String>();
  final String id;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final List<TutorialSection> sections;
  final List<String> checklist;
}
