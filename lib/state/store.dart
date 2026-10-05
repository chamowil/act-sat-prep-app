import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/content.dart';
import '../models/study.dart';
import '../models/subject.dart';

/// Subscription state, backed by StoreKit on iOS and Play Billing on Android
/// through the `in_app_purchase` plugin.
///
/// Entitlement is cached locally so a returning subscriber is never shown
/// locked content while the store is still being asked. On every launch the
/// app re-queries the store; if the store is reachable and reports no active
/// subscription, the cached entitlement is cleared.
class StoreManager extends ChangeNotifier {
  StoreManager(this._prefs, this._content) {
    _isPro = _prefs.getBool('isPro') ?? false;
  }

  final SharedPreferences _prefs;
  final Content _content;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _isPro = false;
  bool _available = false;
  bool _loading = false;
  bool _purchasing = false;
  bool _sawEntitlement = false;
  List<ProductDetails> _products = [];
  String? error;

  bool get isPro => _isPro;
  bool get storeAvailable => _available;
  bool get isLoading => _loading;
  bool get isPurchasing => _purchasing;
  List<ProductDetails> get products => _products;

  ProductDetails? get monthly => _find(AppConfig.monthlyProductId);
  ProductDetails? get yearly => _find(AppConfig.yearlyProductId);

  /// Google Play returns one [ProductDetails] per offer of a subscription (the
  /// base plan, plus any free-trial offer the user is eligible for). Pick the
  /// trial offer when Play offers one, otherwise the plain base plan. StoreKit
  /// returns exactly one entry per product.
  ProductDetails? _find(String id) {
    final matches = _products.where((p) => p.id == id).toList();
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;
    ProductDetails? basePlan;
    for (final p in matches) {
      final phases = _phases(p);
      if (phases == null) continue;
      if (phases.length > 1 && phases.first.priceAmountMicros == 0) return p;
      basePlan ??= p;
    }
    return basePlan ?? matches.first;
  }

  List<PricingPhaseWrapper>? _phases(ProductDetails p) {
    if (p is! GooglePlayProductDetails) return null;
    final i = p.subscriptionIndex;
    final offers = p.productDetails.subscriptionOfferDetails;
    if (i == null || offers == null || i >= offers.length) return null;
    return offers[i].pricingPhases;
  }

  /// The recurring price as the store formats it (never the $0 trial phase).
  String displayPrice(ProductDetails p) => _phases(p)?.last.formattedPrice ?? p.price;

  double recurringPrice(ProductDetails p) {
    final last = _phases(p)?.last;
    return last == null ? p.rawPrice : last.priceAmountMicros / 1000000.0;
  }

  /// Length of the free trial in days, or null if there is none to show.
  ///
  /// On Android this is read from the Play offer. The StoreKit 2 plugin does
  /// not expose introductory offers, so on iOS the yearly plan's trial length
  /// comes from [AppConfig.yearlyTrialDays]; App Store Connect must have a
  /// matching introductory offer, and Apple's purchase sheet shows the exact
  /// terms and eligibility.
  int? trialDays(ProductDetails p) {
    final phases = _phases(p);
    if (phases != null) {
      if (phases.length < 2 || phases.first.priceAmountMicros != 0) return null;
      final days = _isoDays(phases.first.billingPeriod);
      return days > 0 ? days : null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        p.id == AppConfig.yearlyProductId &&
        AppConfig.yearlyTrialDays > 0) {
      return AppConfig.yearlyTrialDays;
    }
    return null;
  }

  static int _isoDays(String iso) {
    final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(iso);
    if (m == null) return 0;
    int g(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    return g(1) * 365 + g(2) * 30 + g(3) * 7 + g(4);
  }

  Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) {
      notifyListeners();
      return;
    }
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      error = 'Purchase failed. Please try again.';
      _purchasing = false;
      notifyListeners();
    });
    await loadProducts();
    await _verifyEntitlement();
  }

  Future<void> loadProducts() async {
    if (!_available) return;
    _loading = true;
    notifyListeners();
    try {
      final r = await _iap.queryProductDetails(AppConfig.productIds);
      _products = r.productDetails;
      error = _products.isEmpty
          ? 'Subscription options are not available right now. Check your connection and try again.'
          : null;
    } catch (_) {
      error = 'Could not load subscription options. Check your connection and try again.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Asks the store for current entitlements. If none arrive, the cache is cleared.
  Future<void> _verifyEntitlement() async {
    _sawEntitlement = false;
    try {
      await _iap.restorePurchases();
    } catch (_) {
      return; // Store unreachable: keep the cached entitlement.
    }
    await Future<void>.delayed(const Duration(seconds: 6));
    if (!_sawEntitlement && _isPro && _products.isNotEmpty) {
      _setPro(false);
    }
  }

  Future<void> restorePurchases() async {
    error = null;
    _sawEntitlement = false;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (_) {
      error = 'Could not reach the store. Please try again.';
      notifyListeners();
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!_isPro) {
      error = 'No active subscription was found for this account.';
      notifyListeners();
    }
  }

  Future<void> purchase(ProductDetails product) async {
    error = null;
    _purchasing = true;
    notifyListeners();
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _purchasing = false;
        error = 'The purchase could not be started.';
        notifyListeners();
      }
    } catch (e) {
      _purchasing = false;
      error = 'The purchase could not be started.';
      notifyListeners();
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          error = 'Your purchase is pending approval.';
        case PurchaseStatus.error:
          _purchasing = false;
          error = 'Purchase failed. Please try again.';
        case PurchaseStatus.canceled:
          _purchasing = false;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (AppConfig.productIds.contains(p.productID)) {
            _sawEntitlement = true;
            _purchasing = false;
            error = null;
            _setPro(true);
          }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  void _setPro(bool v) {
    _isPro = v;
    _prefs.setBool('isPro', v);
    notifyListeners();
  }

  /// Percent saved by the yearly plan versus twelve monthly payments.
  int? get yearlySavingsPercent {
    final m = monthly, y = yearly;
    if (m == null || y == null || recurringPrice(m) <= 0) return null;
    final mp = recurringPrice(m) * 12;
    final p = ((mp - recurringPrice(y)) / mp * 100).round();
    return p > 0 ? p : null;
  }

  // ---- Gating --------------------------------------------------------------

  bool isExamUnlocked(int examIndex) => _isPro || examIndex < AppConfig.freeExamCount;

  bool isPracticeQuestionUnlocked(int index) => _isPro || index < AppConfig.freePracticeLimit;

  bool isTutorialUnlocked(Tutorial t) {
    if (_isPro) return true;
    final siblings = _content.tutorialsFor(t.subject);
    final i = siblings.indexWhere((x) => x.id == t.id);
    return i >= 0 && i < AppConfig.freeTutorialLimit;
  }

  /// Free flashcards: the English / Reading & Writing decks. Everything else is Pro.
  bool isDeckUnlocked(FlashcardDeck d) =>
      _isPro || d.subject == Subject.english || d.subject == Subject.satrw;

  /// Reference: the first three entries in each category are free.
  bool isReferenceUnlocked(ReferenceEntry e) {
    if (_isPro) return true;
    final inCategory = _content.reference.where((r) => r.category == e.category).toList();
    return inCategory.indexWhere((r) => r.id == e.id) < 3;
  }

  /// Writing: the first prompt is free.
  bool isPromptUnlocked(int index) => _isPro || index == 0;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
