import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/app/radar_application.dart';

void main() {
  testWidgets('analyzes a suspicious message and shows the verdict', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadarApplication());

    expect(find.text('Analyser le message'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Je vous ai envoyé 25 000 FCFA par erreur, merci de me les renvoyer.',
    );
    await tester.ensureVisible(find.text('Analyser le message'));
    await tester.tap(find.text('Analyser le message'));
    await tester.pumpAndSettle();

    expect(find.text('Message dangereux'), findsOneWidget);
    expect(find.text('Que faire maintenant ?'), findsOneWidget);
  });

  testWidgets('shows an error when the message is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadarApplication());

    await tester.ensureVisible(find.text('Analyser le message'));
    await tester.tap(find.text('Analyser le message'));
    await tester.pumpAndSettle();

    expect(find.text('Veuillez coller ou saisir un message à analyser.'), findsOneWidget);
  });
}
