import 'package:act_sat_prep/data/content.dart';
import 'package:act_sat_prep/models/subject.dart';
import 'package:act_sat_prep/state/progress.dart';
import 'package:act_sat_prep/state/settings.dart';
import 'package:act_sat_prep/state/store.dart';
import 'package:act_sat_prep/ui/practice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, SharedPreferences prefs, Content content) {
  return MultiProvider(
    providers: [
      Provider<Content>.value(value: content),
      ChangeNotifierProvider(create: (_) => AppSettings(prefs, content)),
      ChangeNotifierProvider(create: (_) => ProgressStore(prefs, content)),
      ChangeNotifierProvider(create: (_) => FlashcardScheduler(prefs, content)),
      ChangeNotifierProvider(create: (_) => StoreManager(prefs, content)),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Content content;
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    content = await Content.load();
  });

  for (final subject in [Subject.satrw, Subject.satmath, Subject.english]) {
    testWidgets('practice session reveals feedback (${subject.name})', (tester) async {
      final qs = content.questionsFor(subject).take(3).toList();
      await tester.pumpWidget(_app(PracticeSessionScreen(title: 'T', questions: qs), prefs, content));
      await tester.pumpAndSettle();
      final choiceA = find.bySemanticsLabel(RegExp(r'^Choice A\.'));
      await tester.ensureVisible(choiceA);
      await tester.pumpAndSettle();
      await tester.tap(choiceA);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Next Question'), findsOneWidget);
      expect(find.text(qs.first.explanation, skipOffstage: false), findsOneWidget);
    });
  }
}
