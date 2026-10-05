import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/subject.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import '../state/store.dart';
import 'paywall.dart';
import 'theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final store = context.watch<StoreManager>();
    final cs = Theme.of(context).colorScheme;
    final exam = settings.exam;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              color: store.isPro ? Colors.green.withValues(alpha: 0.12) : cs.primaryContainer,
              child: ListTile(
                leading: Icon(store.isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                    color: store.isPro ? Colors.green : cs.primary, size: 30),
                title: Text(store.isPro ? 'Pro is active' : 'Upgrade to Pro',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(store.isPro
                    ? 'All questions, exams, and tutorials are unlocked.'
                    : 'Unlock every question, mock exam, and tutorial.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showPaywall(context),
              ),
            ),
            const SectionHeader('Your test'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Exam', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<ExamType>(
                    showSelectedIcon: false,
                    segments: [for (final e in ExamType.values) ButtonSegment(value: e, label: Text(e.label))],
                    selected: {exam},
                    onSelectionChanged: (s) => settings.setExam(s.first),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Expanded(
                        child: Text('Target score', style: TextStyle(fontWeight: FontWeight.w600))),
                    Text('${settings.targetScore}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.primary)),
                  ]),
                  Slider(
                    min: exam.minScore.toDouble(),
                    max: exam.maxScore.toDouble(),
                    divisions: (exam.maxScore - exam.minScore) ~/ exam.targetStep,
                    value: settings.targetScore.toDouble().clamp(exam.minScore.toDouble(), exam.maxScore.toDouble()),
                    label: '${settings.targetScore}',
                    onChanged: (v) => settings.setTarget(
                        exam == ExamType.sat ? (v / 10).round() * 10 : v.round()),
                  ),
                ]),
              ),
            ),
            if (exam == ExamType.act) ...[
              const SizedBox(height: 10),
              Card(
                child: SwitchListTile(
                  title: const Text('Include Science section'),
                  subtitle: const Text(
                      'Turn off if you are taking the ACT without Science. Mock exams and score predictions will skip it.'),
                  value: settings.includesScience,
                  onChanged: settings.setIncludesScience,
                ),
              ),
            ],
            const SectionHeader('Study plan'),
            Card(
              child: Column(children: [
                ListTile(
                  title: const Text('Daily practice goal'),
                  trailing: DropdownButton<int>(
                    value: settings.dailyMinutes,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final m in AppSettings.dailyMinuteOptions)
                        DropdownMenuItem(value: m, child: Text('$m min')),
                    ],
                    onChanged: (v) => v == null ? null : settings.setDailyMinutes(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text('${exam.label} test date'),
                  subtitle: Text(settings.testDate == null
                      ? 'Not set'
                      : _fmt(settings.testDate!)),
                  trailing: settings.testDate == null
                      ? null
                      : IconButton(
                          tooltip: 'Remove test date',
                          icon: const Icon(Icons.close),
                          onPressed: () => settings.setTestDate(null)),
                  onTap: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: settings.testDate ?? now.add(const Duration(days: 90)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 730)),
                    );
                    if (d != null) settings.setTestDate(d);
                  },
                ),
              ]),
            ),
            const SectionHeader('Subscription'),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: const Text('Restore purchases'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await store.restorePurchases();
                    messenger.showSnackBar(SnackBar(
                        content: Text(store.isPro
                            ? 'Your subscription was restored.'
                            : (store.error ?? 'No active subscription was found.'))));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded),
                  title: const Text('Manage subscription'),
                  onTap: () => openUrl(defaultTargetPlatform == TargetPlatform.iOS
                      ? AppConfig.iosManageSubscriptionsUrl
                      : AppConfig.androidManageSubscriptionsUrl),
                ),
              ]),
            ),
            const SectionHeader('About'),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('Support'),
                  onTap: () => openUrl(AppConfig.supportUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () => openUrl(AppConfig.privacyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Use'),
                  onTap: () => openUrl(AppConfig.termsUrl),
                ),
              ]),
            ),
            const SectionHeader('Data'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Reset all progress', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Deletes your scores, streaks, flashcard history, and settings from this device.'),
                onTap: () => _confirmReset(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ACT® is a registered trademark of ACT, Inc. SAT® is a registered trademark of the College Board. '
              '${AppConfig.appName} is an independent study aid and is not affiliated with, endorsed by, or sponsored by ACT, Inc. or the College Board. '
              'All questions, passages, and tutorials are original practice material.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final settings = context.read<AppSettings>();
    final progress = context.read<ProgressStore>();
    final cards = context.read<FlashcardScheduler>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('This permanently deletes your scores, streaks, flashcard history, saved essays, and settings from this device. It does not cancel a subscription.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await progress.resetAll();
      await cards.resetAll();
      await settings.resetAll();
    }
  }
}
