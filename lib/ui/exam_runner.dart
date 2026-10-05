import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/exam.dart';
import '../models/subject.dart';
import '../state/exam_session.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import 'question_view.dart';
import 'scratchpad.dart';
import 'theme.dart';

/// Runs a timed exam end to end, then shows results.
class ExamRunnerScreen extends StatefulWidget {
  const ExamRunnerScreen({super.key, required this.examIndex, required this.mode});
  final int examIndex;
  final ExamMode mode;

  @override
  State<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<ExamRunnerScreen> {
  late final ExamSession _session;
  ExamResult? _result;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettings>();
    _session = ExamSession(
      exam: settings.exam,
      examIndex: widget.examIndex,
      mode: widget.mode,
      subjects: settings.activeSubjects,
      content: context.read<Content>(),
    )..addListener(_onChange);
  }

  void _onChange() {
    if (_session.isFinished && _result == null && mounted) {
      final result = _session.result();
      context.read<ProgressStore>().saveResult(result);
      final settings = context.read<AppSettings>();
      settings.logPractice(_session.elapsedSeconds);
      if (widget.mode == ExamMode.diagnostic) settings.markDiagnosticDone();
      setState(() => _result = result);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onChange);
    _session.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep Going')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () => Navigator.pop(c, true),
              child: Text(action)),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return ExamResultsScreen(result: _result!, diagnostic: widget.mode == ExamMode.diagnostic);
    }
    final s = _session;
    final q = s.question;
    final cs = Theme.of(context).colorScheme;
    final low = s.secondsRemaining <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirm('Leave the exam?',
            'Your progress in this exam will be lost and no score will be recorded.', 'Leave')) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Leave exam',
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirm('Leave the exam?',
                  'Your progress in this exam will be lost and no score will be recorded.', 'Leave')) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.section.subject.displayName, style: const TextStyle(fontSize: 17)),
            Text(
                'Section ${s.sectionIndex + 1} of ${s.sections.length} · Question ${s.questionIndex + 1} of ${s.section.questions.length}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400)),
          ]),
          actions: [
            Semantics(
              label: 'Time remaining ${s.timeString}',
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (low ? Colors.red : cs.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(s.timeString,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: low ? Colors.red : cs.primary)),
              ),
            ),
            if (q != null)
              IconButton(
                tooltip: 'Scratchpad',
                icon: const Icon(Icons.draw_outlined),
                onPressed: () => showScratchpad(context, q.id),
              ),
            IconButton(
              tooltip: 'Question grid',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: _showGrid,
            ),
          ],
        ),
        body: q == null
            ? const Center(child: Text('No questions in this section.'))
            : QuestionView(
                key: ValueKey(q.id),
                question: q,
                passage: context.read<Content>().passageFor(q),
                selected: s.selectedChoice,
                onSelect: s.select,
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Readable(
              child: Row(children: [
                IconButton.outlined(
                  tooltip: 'Previous question',
                  onPressed: s.questionIndex > 0 ? s.previous : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: q != null && s.flagged.contains(q.id) ? 'Remove flag' : 'Flag for review',
                  onPressed: s.toggleFlag,
                  icon: Icon(q != null && s.flagged.contains(q.id) ? Icons.flag : Icons.flag_outlined,
                      color: q != null && s.flagged.contains(q.id) ? Colors.orange : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: s.isLastQuestion
                      ? FilledButton(
                          onPressed: _endSection,
                          child: Text(s.isLastSection ? 'Finish Exam' : 'End Section'))
                      : FilledButton(onPressed: s.next, child: const Text('Next')),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _endSection() async {
    final s = _session;
    final unanswered = s.section.questions.length - s.answeredInSection;
    final body = unanswered > 0
        ? 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. You cannot return to this section.'
        : 'You cannot return to this section once you continue.';
    if (await _confirm(s.isLastSection ? 'Finish the exam?' : 'End this section?', body,
        s.isLastSection ? 'Finish' : 'Continue')) {
      s.endSection();
    }
  }

  void _showGrid() {
    final s = _session;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${s.answeredInSection} of ${s.section.questions.length} answered',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < s.section.questions.length; i++)
                    _GridCell(
                      number: i + 1,
                      answered: s.answers.containsKey(s.section.questions[i].id),
                      flagged: s.flagged.contains(s.section.questions[i].id),
                      current: i == s.questionIndex,
                      onTap: () {
                        s.jump(i);
                        Navigator.pop(c);
                      },
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell(
      {required this.number,
      required this.answered,
      required this.flagged,
      required this.current,
      required this.onTap});
  final int number;
  final bool answered;
  final bool flagged;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Question $number, ${answered ? 'answered' : 'unanswered'}${flagged ? ', flagged' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: answered ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: current ? cs.tertiary : (flagged ? Colors.orange : Colors.transparent), width: 2.5),
          ),
          child: Text('$number',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: answered ? cs.onPrimary : cs.onSurface)),
        ),
      ),
    );
  }
}

/// Score summary shown after an exam or diagnostic.
class ExamResultsScreen extends StatelessWidget {
  const ExamResultsScreen({super.key, required this.result, this.diagnostic = false});
  final ExamResult result;
  final bool diagnostic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final target = context.watch<AppSettings>().targetScore;
    final exam = result.exam;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(diagnostic ? 'Diagnostic Results' : 'Exam ${result.examNumber} Results'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Readable(
            child: Column(children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(children: [
                    Text(exam == ExamType.act ? 'Composite score' : 'Total score',
                        style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    Text('${result.composite}',
                        style: TextStyle(
                            fontSize: 72, fontWeight: FontWeight.w800, color: cs.primary, height: 1.1)),
                    Text(exam.scoreLabel, style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Pill(
                      result.composite >= target
                          ? 'Target of $target reached'
                          : '${target - result.composite} below your target of $target',
                      icon: result.composite >= target ? Icons.emoji_events : Icons.flag_outlined,
                      color: result.composite >= target ? Colors.green : Colors.orange,
                    ),
                  ]),
                ),
              ),
              const SectionHeader('By section'),
              for (final s in result.sections) ...[
                Card(
                  child: ListTile(
                    leading: IconBadge(s.subject.icon, color: s.subject.color),
                    title: Text(s.subject.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.correct} of ${s.total} correct'),
                    trailing: Text('${s.scaled}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (diagnostic) ...[
                const SizedBox(height: 8),
                Text(
                  'This is your starting point. Practice by subject to improve the topics you missed, and retake a mock exam in a few weeks to see your progress.',
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            ]),
          ),
        ],
      ),
    );
  }
}
