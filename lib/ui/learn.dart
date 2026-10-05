import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/study.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import '../state/store.dart';
import 'flashcards.dart';
import 'paywall.dart';
import 'reference.dart';
import 'theme.dart';
import 'writing.dart';

IconData tutorialIcon(String symbol, Subject subject) => switch (symbol) {
      'function' => Icons.functions_rounded,
      'chart' => Icons.bar_chart_rounded,
      'triangle' => Icons.change_history_rounded,
      'book' => Icons.menu_book_rounded,
      'pencil' => Icons.edit_rounded,
      'list' => Icons.format_list_bulleted_rounded,
      'magnifier' => Icons.search_rounded,
      _ => subject.icon,
    };

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final content = context.read<Content>();
    final store = context.watch<StoreManager>();
    final progress = context.watch<ProgressStore>();
    final exam = settings.exam;

    final results = _query.trim().isEmpty
        ? const <Tutorial>[]
        : content.tutorialsForExam(exam).where((t) {
            final q = _query.trim().toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q) ||
                t.summary.toLowerCase().contains(q);
          }).toList();

    Widget tutorialCard(Tutorial t) {
      final done = progress.isTutorialCompleted(t.id);
      final unlocked = store.isTutorialUnlocked(t);
      return NavCard(
        icon: tutorialIcon(t.symbolName, t.subject),
        color: t.subject.color,
        title: t.title,
        subtitle: '${t.estimatedMinutes} min · ${t.summary}',
        locked: !unlocked,
        trailing: done ? const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.check_circle_rounded, color: Colors.green),
        ) : null,
        onTap: () => unlocked
            ? Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => TutorialDetailScreen(tutorial: t)))
            : showPaywall(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SearchBar(
              controller: _search,
              hintText: 'Search tutorials',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          })),
              ],
            ),
            if (_query.trim().isNotEmpty) ...[
              const SectionHeader('Results'),
              if (results.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No tutorials match your search.'))
              else
                for (final t in results) ...[tutorialCard(t), const SizedBox(height: 10)],
            ] else ...[
              const SectionHeader('Study tools'),
              NavCard(
                icon: Icons.style_rounded,
                color: Theme.of(context).colorScheme.primary,
                title: 'Flashcards',
                subtitle: 'Spaced-repetition decks',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => const FlashcardsScreen())),
              ),
              if (exam == ExamType.act) ...[
                const SizedBox(height: 10),
                NavCard(
                  icon: Icons.menu_book_rounded,
                  color: Colors.teal,
                  title: 'Quick Reference',
                  subtitle: 'Grammar rules, formulas, and strategy',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => const ReferenceScreen())),
                ),
                const SizedBox(height: 10),
                NavCard(
                  icon: Icons.edit_note_rounded,
                  color: Colors.pink,
                  title: 'Writing',
                  subtitle: 'Guides, prompts, and scored sample essays',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => const WritingScreen())),
                ),
              ],
              for (final subject in exam.tutorialSubjects) ...[
                SectionHeader('${subject.displayName} tutorials'),
                for (final cat in content.tutorialCategories(subject)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                    child: Text(cat,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  for (final t in content.tutorialsFor(subject).where((t) => t.category == cat)) ...[
                    tutorialCard(t),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ],
          ]),
        ),
      ]),
    );
  }
}

class TutorialDetailScreen extends StatelessWidget {
  const TutorialDetailScreen({super.key, required this.tutorial});
  final Tutorial tutorial;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final done = progress.isTutorialCompleted(tutorial.id);
    final cs = Theme.of(context).colorScheme;
    final t = tutorial;

    Widget bulletList(List<String> items, IconData icon, Color color) => Column(children: [
          for (final s in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 18, color: color)),
                const SizedBox(width: 10),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 15, height: 1.45))),
              ]),
            ),
        ]);

    return Scaffold(
      appBar: AppBar(title: Text(t.category)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconBadge(tutorialIcon(t.symbolName, t.subject), color: t.subject.color, size: 52),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(t.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2))),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              Pill('${t.estimatedMinutes} min read', icon: Icons.schedule),
              Pill(t.subject.displayName, color: t.subject.color),
            ]),
            const SizedBox(height: 12),
            Text(t.summary, style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant, height: 1.45)),
            for (final s in t.sections) ...[
              const SizedBox(height: 22),
              Text(s.heading, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(s.body, style: const TextStyle(fontSize: 16, height: 1.55)),
            ],
            if (t.keyFacts.isNotEmpty) ...[
              const SectionHeader('Key facts'),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: bulletList(t.keyFacts, Icons.bolt_rounded, Colors.orange))),
            ],
            if (t.examples.isNotEmpty) ...[
              const SectionHeader('Worked examples'),
              for (final e in t.examples) ...[_ExampleCard(example: e), const SizedBox(height: 10)],
            ],
            if (t.tips.isNotEmpty) ...[
              const SectionHeader('Test-day tips'),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: bulletList(t.tips, Icons.lightbulb_rounded, Colors.amber.shade700))),
            ],
            const SizedBox(height: 24),
            done
                ? OutlinedButton.icon(
                    onPressed: () => progress.toggleTutorial(t.id),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Completed. Tap to undo'))
                : FilledButton.icon(
                    onPressed: () => progress.toggleTutorial(t.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as complete')),
          ]),
        ),
      ]),
    );
  }
}

class _ExampleCard extends StatefulWidget {
  const _ExampleCard({required this.example});
  final WorkedExample example;

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = widget.example;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.problem, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 10),
          if (_show) ...[
            for (var i = 0; i < e.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.steps[i], style: const TextStyle(fontSize: 15, height: 1.45))),
                ]),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('Answer: ${e.answer}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ] else
            TextButton.icon(
              onPressed: () => setState(() => _show = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Show solution'),
            ),
        ]),
      ),
    );
  }
}
