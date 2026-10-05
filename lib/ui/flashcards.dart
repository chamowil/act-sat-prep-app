import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/study.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import '../state/store.dart';
import 'paywall.dart';
import 'theme.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<AppSettings>().exam;
    final decks = context.read<Content>().decksFor(exam);
    final scheduler = context.watch<FlashcardScheduler>();
    final store = context.watch<StoreManager>();
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(children: [
            for (final d in decks) ...[
              Builder(builder: (context) {
                final due = scheduler.dueCount(d);
                final unlocked = store.isDeckUnlocked(d);
                return NavCard(
                  icon: d.subject.icon,
                  color: d.subject.color,
                  title: d.name,
                  subtitle:
                      '${d.cards.length} cards · ${scheduler.learnedCount(d)} learned${due > 0 ? ' · $due due' : ''}',
                  locked: !unlocked,
                  onTap: () => unlocked
                      ? Navigator.push(context,
                          MaterialPageRoute<void>(builder: (_) => DeckStudyScreen(deck: d)))
                      : showPaywall(context),
                );
              }),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ]),
    );
  }
}

class DeckStudyScreen extends StatefulWidget {
  const DeckStudyScreen({super.key, required this.deck});
  final FlashcardDeck deck;

  @override
  State<DeckStudyScreen> createState() => _DeckStudyScreenState();
}

class _DeckStudyScreenState extends State<DeckStudyScreen> {
  late List<Flashcard> _queue;
  int _index = 0;
  bool _flipped = false;
  int _reviewed = 0;

  @override
  void initState() {
    super.initState();
    _queue = context.read<FlashcardScheduler>().dueCards(widget.deck);
  }

  void _grade(RecallGrade g) {
    context.read<FlashcardScheduler>().record(_queue[_index].id, g);
    setState(() {
      _reviewed++;
      _flipped = false;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_index >= _queue.length) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, size: 64, color: Colors.green.shade500),
              const SizedBox(height: 12),
              Text(_queue.isEmpty ? 'All caught up' : 'Session complete',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                  _queue.isEmpty
                      ? 'No cards are due in this deck. Come back later.'
                      : 'You reviewed $_reviewed card${_reviewed == 1 ? '' : 's'}.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                  width: 220,
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
            ]),
          ),
        ),
      );
    }

    final card = _queue[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deck.name} · ${_index + 1}/${_queue.length}'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: _index / _queue.length)),
      ),
      body: Readable(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(
            child: Semantics(
              button: true,
              label: _flipped ? 'Answer: ${card.back}. Tap to hide.' : 'Question: ${card.front}. Tap to reveal the answer.',
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Card(
                    key: ValueKey(_flipped),
                    color: _flipped ? cs.primaryContainer : null,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_flipped ? 'ANSWER' : 'QUESTION',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: cs.onSurfaceVariant)),
                          const SizedBox(height: 14),
                          Text(_flipped ? card.back : card.front,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: _flipped ? 20 : 24, fontWeight: FontWeight.w600, height: 1.35)),
                          if (!_flipped && card.hint.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Hint: ${card.hint}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                          ],
                          if (!_flipped) ...[
                            const SizedBox(height: 24),
                            Text('Tap to reveal', style: TextStyle(color: cs.primary)),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_flipped)
            Row(children: [
              for (final g in RecallGrade.values) ...[
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => _grade(g),
                    child: Text(switch (g) {
                      RecallGrade.forgot => 'Forgot',
                      RecallGrade.hard => 'Hard',
                      RecallGrade.good => 'Good',
                      RecallGrade.easy => 'Easy',
                    }, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                if (g != RecallGrade.easy) const SizedBox(width: 8),
              ],
            ])
          else
            const SizedBox(height: 52),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
