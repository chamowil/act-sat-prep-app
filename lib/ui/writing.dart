import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../models/study.dart';
import '../state/settings.dart';
import '../state/store.dart';
import 'paywall.dart';
import 'theme.dart';

class WritingScreen extends StatelessWidget {
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.read<Content>();
    final store = context.watch<StoreManager>();
    return Scaffold(
      appBar: AppBar(title: const Text('Writing')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('How to write the essay'),
            for (final g in content.guides) ...[
              NavCard(
                icon: Icons.lightbulb_outline_rounded,
                color: Colors.pink,
                title: g.title,
                subtitle: '${g.estimatedMinutes} min · ${g.summary}',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute<void>(builder: (_) => GuideDetailScreen(guide: g))),
              ),
              const SizedBox(height: 10),
            ],
            const SectionHeader('Practice prompts'),
            for (var i = 0; i < content.prompts.length; i++) ...[
              Builder(builder: (context) {
                final p = content.prompts[i];
                final unlocked = store.isPromptUnlocked(i);
                final hasSamples = content.samplesFor(p.id).isNotEmpty;
                return NavCard(
                  icon: Icons.edit_note_rounded,
                  color: Colors.purple,
                  title: p.title,
                  subtitle: hasSamples ? 'Includes scored sample essays' : '40-minute timed essay',
                  locked: !unlocked,
                  onTap: () => unlocked
                      ? Navigator.push(context,
                          MaterialPageRoute<void>(builder: (_) => PromptDetailScreen(prompt: p)))
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

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.guide});
  final WritingGuide guide;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Writing Guide')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Readable(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(guide.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(guide.summary,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
              for (final s in guide.sections) ...[
                const SizedBox(height: 20),
                Text(s.heading, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(s.body, style: const TextStyle(fontSize: 16, height: 1.55)),
              ],
              if (guide.checklist.isNotEmpty) ...[
                const SectionHeader('Checklist'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      for (final c in guide.checklist)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_box_outline_blank, size: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(c, style: const TextStyle(fontSize: 15, height: 1.4))),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      );
}

class PromptDetailScreen extends StatelessWidget {
  const PromptDetailScreen({super.key, required this.prompt});
  final WritingPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final samples = context.read<Content>().samplesFor(prompt.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Prompt')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prompt.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(prompt.context, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SectionHeader('Perspectives'),
            for (final p in prompt.perspectives) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(p.text, style: const TextStyle(height: 1.45)),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SectionHeader('Your task'),
            Text(prompt.task, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Write the essay (40 min)'),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute<void>(builder: (_) => EssayEditorScreen(prompt: prompt))),
            ),
            if (samples.isNotEmpty) ...[
              const SectionHeader('Scored sample essays'),
              for (final s in samples) ...[
                NavCard(
                  icon: Icons.star_rounded,
                  color: Colors.amber.shade700,
                  title: s.label,
                  subtitle: 'With grader comments',
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => SampleEssayScreen(sample: s))),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ]),
        ),
      ]),
    );
  }
}

class SampleEssayScreen extends StatelessWidget {
  const SampleEssayScreen({super.key, required this.sample});
  final SampleEssay sample;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(sample.label)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Readable(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sample.essay, style: const TextStyle(fontSize: 16, height: 1.6)),
              const SectionHeader('Grader comments'),
              for (final e in SampleEssay.commentTitles.entries)
                if (sample.comments[e.key] != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(sample.comments[e.key]!, style: const TextStyle(height: 1.45)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ]),
          ),
        ]),
      );
}

/// A 40-minute timed essay editor that autosaves as you type.
class EssayEditorScreen extends StatefulWidget {
  const EssayEditorScreen({super.key, required this.prompt});
  final WritingPrompt prompt;

  @override
  State<EssayEditorScreen> createState() => _EssayEditorScreenState();
}

class _EssayEditorScreenState extends State<EssayEditorScreen> {
  static const _totalSeconds = 40 * 60;
  final _controller = TextEditingController();
  Timer? _timer;
  Timer? _saveDebounce;
  SharedPreferences? _prefs;
  int _remaining = _totalSeconds;
  bool _running = false;
  DateTime? _deadline;
  late final AppSettings _settings;

  String get _key => 'essay.${widget.prompt.id}';

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppSettings>();
    SharedPreferences.getInstance().then((p) {
      _prefs = p;
      final saved = p.getString(_key);
      if (saved != null && mounted) setState(() => _controller.text = saved);
    });
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    _deadline = DateTime.now().add(Duration(seconds: _remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _deadline!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining = left);
      }
    });
    setState(() => _running = true);
  }

  void _onChanged(String _) {
    setState(() {});
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() => _prefs?.setString(_key, _controller.text);

  @override
  void dispose() {
    _timer?.cancel();
    _saveDebounce?.cancel();
    _save();
    final spent = _totalSeconds - _remaining;
    if (spent > 0) Future.microtask(() => _settings.logPractice(spent));
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final words = _controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).length;
    final m = _remaining ~/ 60, s = _remaining % 60;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Essay'),
        actions: [
          TextButton.icon(
            onPressed: _toggleTimer,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            label: Text('$m:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: Readable(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(widget.prompt.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.prompt.context, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 10),
                for (final p in widget.prompt.perspectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${p.label}: ${p.text}', style: const TextStyle(height: 1.4)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Start writing. Your essay saves automatically.',
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              Text('$words words', style: TextStyle(color: cs.onSurfaceVariant)),
              const Spacer(),
              Text('Autosaved', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}
