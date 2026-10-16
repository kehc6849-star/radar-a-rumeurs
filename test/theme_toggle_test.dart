import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/app/radar_application.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeMode _readThemeMode(WidgetTester tester) {
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('switches to the dark theme, then back to the light theme', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(const RadarApplication());
    await tester.pumpAndSettle();

    expect(_readThemeMode(tester), ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    expect(_readThemeMode(tester), ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    expect(_readThemeMode(tester), ThemeMode.light);
  });

  testWidgets('starts in the dark theme when it was saved', (
      WidgetTester tester,
      ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dark_mode': true,
    });

    await tester.pumpWidget(const RadarApplication());
    await tester.pumpAndSettle();

    expect(_readThemeMode(tester), ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });
}