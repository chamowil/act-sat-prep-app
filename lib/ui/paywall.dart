import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/content.dart';
import '../models/subject.dart';
import '../state/store.dart';
import 'theme.dart';

/// Opens the subscription paywall as a full-screen modal.
Future<void> showPaywall(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const PaywallScreen()),
    );

Future<void> openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selected = AppConfig.yearlyProductId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreManager>();
    final content = context.read<Content>();
    final cs = Theme.of(context).colorScheme;

    if (store.isPro) {
      return Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: const Center(
            child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text("You're Pro", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Everything is unlocked. Thank you for subscribing!', textAlign: TextAlign.center),
          ]),
        )),
      );
    }

    final yearly = store.yearly, monthly = store.monthly;
    final selectedProduct = _selected == AppConfig.yearlyProductId ? yearly : monthly;
    final selectedTrial = selectedProduct == null ? null : store.trialDays(selectedProduct);

    return Scaffold(
      appBar: AppBar(leading: const CloseButton(), title: const Text('')),
      body: SafeArea(
        child: Readable(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Icon(Icons.workspace_premium_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 12),
              const Text('Unlock Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Everything you need to hit your target score.',
                  textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 20),
              _Feature(Icons.quiz_rounded,
                  'All ${formatCount(content.countFor(ExamType.act) + content.countFor(ExamType.sat))} practice questions for ACT and SAT'),
              _Feature(Icons.timer_rounded,
                  '${ExamType.act.mockExamCount + ExamType.sat.mockExamCount} timed mock exams in quick and full-length formats'),
              const _Feature(Icons.menu_book_rounded, 'Every tutorial, flashcard deck, and reference entry'),
              const _Feature(Icons.edit_note_rounded, 'All ACT Writing prompts, guides, and scored samples'),
              const _Feature(Icons.insights_rounded, 'Full progress tracking and score prediction'),
              const SizedBox(height: 20),
              if (store.isLoading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (yearly == null && monthly == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Text(store.error ?? 'Subscription options are unavailable right now.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: store.loadProducts, child: const Text('Try Again')),
                    ]),
                  ),
                )
              else ...[
                if (yearly != null)
                  _PlanTile(
                    product: yearly,
                    title: 'Yearly',
                    detail: store.trialDays(yearly) != null
                        ? '${store.trialDays(yearly)}-day free trial for eligible new subscribers, then ${store.displayPrice(yearly)}/year'
                        : '${store.displayPrice(yearly)} per year',
                    badge: store.yearlySavingsPercent == null
                        ? null
                        : 'Save ${store.yearlySavingsPercent}%',
                    selected: _selected == yearly.id,
                    onTap: () => setState(() => _selected = yearly.id),
                  ),
                if (monthly != null) ...[
                  const SizedBox(height: 10),
                  _PlanTile(
                    product: monthly,
                    title: 'Monthly',
                    detail: '${store.displayPrice(monthly)} per month',
                    selected: _selected == monthly.id,
                    onTap: () => setState(() => _selected = monthly.id),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: store.isPurchasing || selectedProduct == null
                      ? null
                      : () => store.purchase(selectedProduct),
                  child: store.isPurchasing
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(selectedTrial != null ? 'Try Free, Then Subscribe' : 'Subscribe'),
                ),
              ],
              if (store.error != null && (yearly != null || monthly != null))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(store.error!,
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ),
              TextButton(onPressed: store.restorePurchases, child: const Text('Restore Purchases')),
              const SizedBox(height: 8),
              Text(_legalText(selectedProduct, store),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                    onPressed: () => openUrl(AppConfig.termsUrl), child: const Text('Terms of Use')),
                TextButton(
                    onPressed: () => openUrl(AppConfig.privacyUrl),
                    child: const Text('Privacy Policy')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _legalText(ProductDetails? p, StoreManager store) {
    final account = defaultTargetPlatform == TargetPlatform.iOS ? 'your Apple Account' : 'your Google Play account';
    final billing = defaultTargetPlatform == TargetPlatform.iOS ? 'Apple ID account settings' : 'Google Play subscription settings';
    final price = p == null
        ? ''
        : ' ${store.displayPrice(p)} is charged ${p.id == AppConfig.yearlyProductId ? 'yearly' : 'monthly'}.';
    return 'Payment is charged to $account at confirmation of purchase.$price '
        'The subscription renews automatically unless canceled at least 24 hours before the end of the current period. '
        'Manage or cancel any time in your $billing.'
        '${p != null && store.trialDays(p) != null ? ' Any unused portion of a free trial is forfeited when you subscribe.' : ''}';
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.3))),
        ]),
      );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.product,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final ProductDetails product;
  final String title;
  final String detail;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan. $detail',
      child: Material(
        color: selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? cs.primary : cs.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    if (badge != null) ...[const SizedBox(width: 8), Pill(badge!, color: Colors.green)],
                  ]),
                  const SizedBox(height: 2),
                  Text(detail, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
