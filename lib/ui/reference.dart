import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content.dart';
import '../models/subject.dart';
import '../models/study.dart';
import '../state/store.dart';
import 'paywall.dart';
import 'theme.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final content = context.read<Content>();
    final store = context.watch<StoreManager>();

    Widget entryCard(ReferenceEntry e) {
      final unlocked = store.isReferenceUnlocked(e);
      return NavCard(
        icon: e.subject.icon,
        color: e.subject.color,
        title: e.title,
        subtitle: e.summary,
        locked: !unlocked,
        onTap: () => unlocked
            ? Navigator.push(
                context, MaterialPageRoute<void>(builder: (_) => ReferenceDetailScreen(entry: e)))
            : showPaywall(context),
      );
    }

    final results = content.searchReference(_query);
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Reference')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SearchBar(
              hintText: 'Search the reference',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
            ),
            if (_query.trim().isNotEmpty) ...[
              const SectionHeader('Results'),
              if (results.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('No entries match your search.')),
              for (final e in results) ...[entryCard(e), const SizedBox(height: 10)],
            ] else
              for (final cat in content.referenceCategories) ...[
                SectionHeader(cat),
                for (final e in content.reference.where((r) => r.category == cat)) ...[
                  entryCard(e),
                  const SizedBox(height: 10),
                ],
              ],
          ]),
        ),
      ]),
    );
  }
}

class ReferenceDetailScreen extends StatelessWidget {
  const ReferenceDetailScreen({super.key, required this.entry});
  final ReferenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(entry.category)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 10),
            Text(entry.body, style: const TextStyle(fontSize: 16, height: 1.55)),
            if (entry.examples.isNotEmpty) ...[
              const SectionHeader('Examples'),
              for (final ex in entry.examples) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (ex.wrong.isNotEmpty)
                        _line(Icons.close_rounded, Colors.red, ex.wrong),
                      if (ex.right.isNotEmpty)
                        _line(Icons.check_rounded, Colors.green, ex.right),
                      if (ex.why.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(ex.why, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (entry.trap.isNotEmpty) ...[
              const SectionHeader('Watch out'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.trap, style: const TextStyle(height: 1.45))),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _line(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ]),
      );
}
