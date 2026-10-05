import 'package:flutter/material.dart';

import '../models/question.dart';
import 'theme.dart';

/// Renders a passage, turning `[n]text[/n]` markers (ACT English) into
/// underlined, numbered segments.
class PassageText extends StatelessWidget {
  const PassageText(this.text, {super.key});
  final String text;

  static final _marker = RegExp(r'\[(\d+)\](.*?)\[/\1\]', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.copyWith(fontSize: 16, height: 1.5);
    final color = Theme.of(context).colorScheme.primary;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _marker.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          padding: const EdgeInsets.only(right: 2),
          child: Text.rich(TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.only(right: 3),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(m.group(1)!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ),
            ),
            TextSpan(
                text: m.group(2),
                style: base.copyWith(
                    decoration: TextDecoration.underline, decorationColor: color)),
          ])),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// A question with its passage/stimulus and answer choices.
///
/// In practice mode, set [revealed] to show right/wrong feedback and the
/// explanation. In exam mode, leave it false so only the selection shows.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.passage,
    required this.selected,
    required this.onSelect,
    this.revealed = false,
    this.header,
  });

  final Question question;
  final Passage? passage;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool revealed;
  final Widget? header;

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final passageCard = passage == null
        ? null
        : Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(passage!.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                PassageText(passage!.text),
              ]),
            ),
          );

    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ?header,
      if (question.stimulus != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          ),
          child: Text(question.stimulus!, style: const TextStyle(fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 16),
      ],
      Text(question.prompt,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
      const SizedBox(height: 16),
      for (var i = 0; i < question.choices.length; i++) ...[
        _ChoiceTile(
          letter: _letters[i],
          text: question.choices[i],
          state: _stateFor(i),
          onTap: revealed ? null : () => onSelect(i),
        ),
        const SizedBox(height: 10),
      ],
      if (revealed) ...[
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selected == question.correctIndex ? 'Correct' : 'Explanation',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected == question.correctIndex ? Colors.green.shade600 : cs.primary)),
            const SizedBox(height: 6),
            Text(question.explanation, style: const TextStyle(fontSize: 15, height: 1.45)),
          ]),
        ),
      ],
    ]);

    if (wide && passageCard != null) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: passageCard)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: body)),
      ]);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Readable(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (passageCard != null) ...[passageCard, const SizedBox(height: 16)],
          body,
        ]),
      ),
    );
  }

  _ChoiceState _stateFor(int i) {
    if (revealed) {
      if (i == question.correctIndex) return _ChoiceState.correct;
      if (i == selected) return _ChoiceState.wrong;
      return _ChoiceState.idle;
    }
    return i == selected ? _ChoiceState.selected : _ChoiceState.idle;
  }
}

enum _ChoiceState { idle, selected, correct, wrong }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.letter, required this.text, required this.state, this.onTap});
  final String letter;
  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color border, Color fill, Color badge) = switch (state) {
      _ChoiceState.idle => (cs.outlineVariant, Colors.transparent, cs.surfaceContainerHighest),
      _ChoiceState.selected => (cs.primary, cs.primary.withValues(alpha: 0.08), cs.primary),
      _ChoiceState.correct => (Colors.green, Colors.green.withValues(alpha: 0.10), Colors.green),
      _ChoiceState.wrong => (Colors.red, Colors.red.withValues(alpha: 0.10), Colors.red),
    };
    final lit = state != _ChoiceState.idle;
    return Semantics(
      button: true,
      selected: state == _ChoiceState.selected,
      label: 'Choice $letter. $text',
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: lit ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badge, shape: BoxShape.circle),
                child: state == _ChoiceState.correct
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : state == _ChoiceState.wrong
                        ? const Icon(Icons.close, size: 16, color: Colors.white)
                        : Text(letter,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: state == _ChoiceState.selected ? Colors.white : null)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
