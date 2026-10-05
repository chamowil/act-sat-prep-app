import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'data/content.dart';
import 'demo_data.dart';
import 'state/progress.dart';
import 'state/settings.dart';
import 'state/store.dart';
import 'ui/onboarding.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final content = await Content.load();
  await seedDemoData(prefs, content);
  final store = StoreManager(prefs, content);
  // Subscription state resolves in the background; the cached entitlement is used meanwhile.
  store.init();

  runApp(MultiProvider(
    providers: [
      Provider<Content>.value(value: content),
      ChangeNotifierProvider(create: (_) => AppSettings(prefs, content)),
      ChangeNotifierProvider(create: (_) => ProgressStore(prefs, content)),
      ChangeNotifierProvider(create: (_) => FlashcardScheduler(prefs, content)),
      ChangeNotifierProvider<StoreManager>.value(value: store),
    ],
    child: const ActSatPrepApp(),
  ));
}

class ActSatPrepApp extends StatelessWidget {
  const ActSatPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppSettings, bool>((s) => s.onboarded);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: onboarded ? const AppShell() : const OnboardingScreen(),
    );
  }
}
