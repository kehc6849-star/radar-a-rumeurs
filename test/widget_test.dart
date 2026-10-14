import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/app/radar_application.dart';
import 'package:radar_a_rumeurs/core/configuration/backend_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

const BackendConfiguration _unreachableServer = BackendConfiguration(
  baseUrl: 'http://127.0.0.1:9',
  accessToken: '',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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
    expect(find.textContaining('règles locales'), findsWidgets);
  });

  testWidgets('shows an error when the message is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadarApplication());

    await tester.ensureVisible(find.text('Analyser le message'));
    await tester.tap(find.text('Analyser le message'));
    await tester.pumpAndSettle();

    expect(
      find.text('Veuillez coller ou saisir un message à analyser.'),
      findsOneWidget,
    );
  });

  testWidgets('hides the screenshot button when no server is configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RadarApplication());
    await tester.pumpAndSettle();

    expect(find.text("Capture d'écran"), findsNothing);
    expect(find.text('Analyse par intelligence artificielle'), findsNothing);
  });

  testWidgets('asks for consent once, and remembers a refusal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const RadarApplication(backendConfiguration: _unreachableServer),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analyse par intelligence artificielle'), findsOneWidget);
    expect(find.text("Capture d'écran"), findsOneWidget);

    await tester.tap(find.text('Rester hors-ligne'));
    await tester.pumpAndSettle();

    expect(find.text('Analyse par intelligence artificielle'), findsNothing);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(preferences.getString('ai_consent_status_v1'), 'declined');
  });

  testWidgets('does not ask again when the user already decided', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ai_consent_status_v1': 'granted',
    });

    await tester.pumpWidget(
      const RadarApplication(backendConfiguration: _unreachableServer),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analyse par intelligence artificielle'), findsNothing);
  });
}
