/// App-wide constants. Everything store-facing lives here so it can be kept in
/// sync with App Store Connect and Google Play Console in one place.
class AppConfig {
  static const appName = 'ACT & SAT Prep';

  /// Subscription product IDs. They must match, character for character, the
  /// product IDs created in App Store Connect and the subscription IDs created
  /// in Google Play Console.
  static const monthlyProductId = 'actprep.pro.monthly';
  static const yearlyProductId = 'actprep.pro.yearly';
  static const productIds = {monthlyProductId, yearlyProductId};

  /// Whether the yearly plan has a free-trial offer configured in the stores.
  /// Keep this in sync with the introductory offer (App Store Connect) / free
  /// trial offer (Play Console); the paywall wording follows it.
  static const yearlyTrialDays = 7;

  static const supportUrl = 'https://chamowil.github.io/act-prep-support/';
  static const privacyUrl = 'https://chamowil.github.io/act-prep-support/privacy.html';
  static const termsUrl = 'https://chamowil.github.io/act-prep-support/terms.html';

  /// Free tier limits.
  static const freePracticeLimit = 10;
  static const freeTutorialLimit = 2;
  static const freeExamCount = 1;

  static const iosManageSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';
  static const androidManageSubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';
}
