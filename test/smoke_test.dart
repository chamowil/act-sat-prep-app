import 'package:act_sat_prep/data/content.dart';
import 'package:act_sat_prep/models/exam.dart';
import 'package:act_sat_prep/models/subject.dart';
import 'package:act_sat_prep/state/progress.dart';
import 'package:act_sat_prep/state/settings.dart';
import 'package:act_sat_prep/state/store.dart';
import 'package:act_sat_prep/ui/exam_runner.dart';
import 'package:act_sat_prep/ui/flashcards.dart';
import 'package:act_sat_prep/ui/learn.dart';
import 'package:act_sat_prep/ui/onboarding.dart';
import 'package:act_sat_prep/ui/paywall.dart';
import 'package:act_sat_prep/ui/practice.dart';
import 'package:act_sat_prep/ui/progress_screen.dart';
import 'package:act_sat_prep/ui/reference.dart';
import 'package:act_sat_prep/ui/settings_screen.dart';
import 'package:act_sat_prep/ui/shell.dart';
import 'package:act_sat_prep/ui/theme.dart';
import 'package:act_sat_prep/ui/writing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every screen for both exams at phone and tablet sizes and fails on
/// any layout or build exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Content content;

  setUpAll(() async => content = await Content.load());

  Future<void> pump(WidgetTester tester, Widget screen, ExamType exam, Size size,
      {bool pro = false}) async {
    SharedPreferences.setMockInitialValues({'exam': exam.name, 'onboarded': true, 'isPro': pro});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<Content>.value(value: content),
        ChangeNotifierProvider(create: (_) => AppSettings(prefs, content)),
        ChangeNotifierProvider(create: (_) => ProgressStore(prefs, content)),
        ChangeNotifierProvider(create: (_) => FlashcardScheduler(prefs, content)),
        ChangeNotifierProvider(create: (_) => StoreManager(prefs, content)),
      ],
      child: MaterialApp(theme: buildTheme(Brightness.light), home: screen),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }

  const sizes = [Size(390, 844), Size(1024, 1366)];
  final screens = <String, Widget Function()>{
    'shell': () => const AppShell(),
    'onboarding': () => const OnboardingScreen(),
    'practice': () => const PracticeScreen(),
    'learn': () => const LearnScreen(),
    'progress': () => const ProgressScreen(),
    'settings': () => const SettingsScreen(),
    'mockExams': () => const MockExamsScreen(),
    'diagnosticIntro': () => const DiagnosticIntroScreen(),
    'flashcards': () => const FlashcardsScreen(),
    'paywall': () => const PaywallScreen(),
    'writing': () => const WritingScreen(),
    'reference': () => const ReferenceScreen(),
  };

  for (final exam in ExamType.values) {
    for (final size in sizes) {
      for (final e in screens.entries) {
        testWidgets('${e.key} / ${exam.name} / ${size.width.toInt()}', (tester) async {
          await pump(tester, e.value(), exam, size);
        });
      }
    }
  }

  for (final exam in ExamType.values) {
    for (final mode in ExamMode.values) {
      testWidgets('exam runner ${exam.name} ${mode.name}', (tester) async {
        await pump(tester, ExamRunnerScreen(examIndex: 0, mode: mode), exam, const Size(390, 844));
        expect(find.text('Next'), findsOneWidget);
        await tester.tap(find.byTooltip('Question grid'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('every tutorial renders', (tester) async {
    for (final t in content.tutorials) {
      await pump(tester, TutorialDetailScreen(tutorial: t), t.subject.exam, const Size(390, 844));
    }
  });

  testWidgets('every passage question renders', (tester) async {
    final seen = <String>{};
    for (final q in content.questions) {
      final key = '${q.subject.name}-${q.passageId ?? ''}';
      if (!seen.add(key)) continue;
      await pump(tester, PracticeSessionScreen(title: 'x', questions: [q]), q.subject.exam,
          const Size(390, 844));
    }
  });
}
