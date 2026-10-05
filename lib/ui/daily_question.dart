import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import 'question_view.dart';
import 'scratchpad.dart';

class DailyQuestionScreen extends StatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppSettings>();
    final q = settings.dailyQuestion();
    if (q == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('No question available.')));
    }
    final answered = _selected != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Question of the Day'), actions: [
        IconButton(
            tooltip: 'Scratchpad',
            icon: const Icon(Icons.draw_outlined),
            onPressed: () => showScratchpad(context, q.id)),
      ]),
      body: QuestionView(
        question: q,
        passage: context.read<Content>().passageFor(q),
        selected: _selected,
        revealed: answered,
        onSelect: (i) {
          if (answered) return;
          context.read<ProgressStore>().recordPractice(q.id, i == q.correctIndex);
          settings.markDailyQuestionAnswered();
          setState(() => _selected = i);
        },
      ),
    );
  }
}
