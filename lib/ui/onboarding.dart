import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/settings.dart';
import 'theme.dart';

/// First-launch setup: choose your test, set a target, a daily goal, and an
/// optional test date.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 4;
  int _step = 0;
  ExamType _exam = ExamType.act;
  final _name = TextEditingController();
  late double _target = ExamType.act.defaultTarget.toDouble();
  int _minutes = 20;
  bool _wantsDate = false;
  DateTime _date = DateTime.now().add(const Duration(days: 90));

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    final s = context.read<AppSettings>();
    s.setExam(_exam);
    s.setName(_name.text.trim());
    s.setTarget(_target.round());
    s.setDailyMinutes(_minutes);
    s.setTestDate(_wantsDate ? _date : null);
    s.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Readable(
          width: 520,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Semantics(
                label: 'Step ${_step + 1} of $_steps',
                child: Row(children: [
                  for (var i = 0; i < _steps; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? cs.primary : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (i < _steps - 1) const SizedBox(width: 6),
                  ],
                ]),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(key: ValueKey(_step), child: _stepBody(context)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                FilledButton(
                  onPressed: () => _step < _steps - 1 ? setState(() => _step++) : _finish(),
                  child: Text(_step == _steps - 1 ? 'Start Studying' : 'Continue'),
                ),
                if (_step > 0)
                  TextButton(onPressed: () => setState(() => _step--), child: const Text('Back')),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _scaffold(IconData icon, String title, String subtitle, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      const SizedBox(height: 16),
      Icon(icon, size: 56, color: cs.primary),
      const SizedBox(height: 16),
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15)),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
      const SizedBox(height: 24),
      ...children,
    ]);
  }

  Widget _stepBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_step) {
      case 0:
        return _scaffold(Icons.school_rounded, 'Welcome to ACT & SAT Prep',
            'Practice questions, tutorials, flashcards, and timed mock exams for both tests. Which one are you preparing for?', [
          for (final e in ExamType.values) ...[
            Semantics(
              button: true,
              selected: _exam == e,
              child: Material(
                color: _exam == e ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _exam == e ? cs.primary : cs.outlineVariant, width: _exam == e ? 2 : 1)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _exam = e;
                    _target = e.defaultTarget.toDouble();
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(_exam == e ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _exam == e ? cs.primary : cs.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(
                              e == ExamType.act
                                  ? 'English, Math, Reading, Science, and Writing'
                                  : 'Reading & Writing and Math',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text('You can switch any time.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your first name (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]);
      case 1:
        return _scaffold(Icons.flag_rounded, 'What score are you aiming for?',
            'This sets the goal on your home screen. You can change it later.', [
          Text('${_target.round()}',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: cs.primary)),
          Text(_exam.scoreLabel, style: TextStyle(color: cs.onSurfaceVariant)),
          Slider(
            min: _exam.minScore.toDouble(),
            max: _exam.maxScore.toDouble(),
            divisions: (_exam.maxScore - _exam.minScore) ~/ _exam.targetStep,
            value: _target,
            label: '${_target.round()}',
            onChanged: (v) => setState(() => _target = _exam == ExamType.sat ? (v / 10).round() * 10.0 : v.roundToDouble()),
          ),
        ]);
      case 2:
        return _scaffold(Icons.timer_rounded, 'Set a daily goal',
            'Short, regular sessions beat cramming. How long can you study each day?', [
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            for (final m in AppSettings.dailyMinuteOptions)
              ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
              ),
          ]),
        ]);
      default:
        return _scaffold(Icons.event_rounded, 'When is your test?',
            'Add your test date for a countdown on your home screen.', [
          SwitchListTile(
            title: const Text('I have a test date'),
            value: _wantsDate,
            onChanged: (v) => setState(() => _wantsDate = v),
          ),
          if (_wantsDate)
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text('${_date.month}/${_date.day}/${_date.year}'),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 730)));
                if (d != null) setState(() => _date = d);
              },
            ),
        ]);
    }
  }
}
