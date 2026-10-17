import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/app/radar_application.dart';
import 'package:radar_a_rumeurs/core/configuration/backend_configuration.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/shared_content.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/shared_content_receiver.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _suspiciousMessage =
    'Je vous ai envoyé 25 000 FCFA par erreur, merci de me les renvoyer.';

const BackendConfiguration _unreachableServer = BackendConfiguration(
  baseUrl: 'http://127.0.0.1:9',
  accessToken: '',
);

/// A receiver that the test controls: no phone, no Android.
class _FakeSharedContentReceiver implements SharedContentReceiver {
  _FakeSharedContentReceiver({this.initialContent});

  SharedContent? initialContent;

  final StreamController<SharedContent> _controller =
      StreamController<SharedContent>.broadcast();

  void shareWhileOpen(SharedContent content) {
    _controller.add(content);
  }

  @override
  Stream<SharedContent> get sharedContentStream => _controller.stream;

  @override
  Future<SharedContent?> takeInitialContent() async {
    final SharedContent? content = initialContent;

    initialContent = null;

    return content;
  }

  @override
  void close() {
    unawaited(_controller.close());
  }
}

SharedScreenshotContent _buildSharedImage() {
  final Uint8List imageBytes = Uint8List(64);

  imageBytes[0] = 0xFF;
  imageBytes[1] = 0xD8;
  imageBytes[2] = 0xFF;

  return SharedScreenshotContent(
    ScreenshotInput(imageBytes: imageBytes, mimeType: 'image/jpeg'),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('analyzes a text shared while the app was closed', (
    WidgetTester tester,
  ) async {
    final _FakeSharedContentReceiver receiver = _FakeSharedContentReceiver(
      initialContent: const SharedTextContent(_suspiciousMessage),
    );
    addTearDown(receiver.close);

    await tester.pumpWidget(RadarApplication(sharedContentReceiver: receiver));
    await tester.pumpAndSettle();

    expect(find.text('Message dangereux'), findsOneWidget);
  });

  testWidgets('analyzes a text shared while the app is already open', (
    WidgetTester tester,
  ) async {
    final _FakeSharedContentReceiver receiver = _FakeSharedContentReceiver();
    addTearDown(receiver.close);

    await tester.pumpWidget(RadarApplication(sharedContentReceiver: receiver));
    await tester.pumpAndSettle();

    expect(find.text('Message dangereux'), findsNothing);

    receiver.shareWhileOpen(const SharedTextContent(_suspiciousMessage));
    await tester.pumpAndSettle();

    expect(find.text('Message dangereux'), findsOneWidget);
  });

  testWidgets('shows the reason when a shared content is rejected', (
    WidgetTester tester,
  ) async {
    const String message =
        'Image trop volumineuse. Choisissez une image plus légère.';
    final _FakeSharedContentReceiver receiver = _FakeSharedContentReceiver();
    addTearDown(receiver.close);

    await tester.pumpWidget(RadarApplication(sharedContentReceiver: receiver));
    await tester.pumpAndSettle();

    receiver.shareWhileOpen(const SharedContentRejected(message));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.text('Message dangereux'), findsNothing);
  });

  testWidgets('explains that an image needs the AI when it is not available', (
    WidgetTester tester,
  ) async {
    final _FakeSharedContentReceiver receiver = _FakeSharedContentReceiver(
      initialContent: _buildSharedImage(),
    );
    addTearDown(receiver.close);

    await tester.pumpWidget(RadarApplication(sharedContentReceiver: receiver));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "La lecture d'une image demande l'analyse IA, qui n'est pas disponible ici.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not read a shared image when the user refuses the AI', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ai_consent_status_v1': 'declined',
    });
    final _FakeSharedContentReceiver receiver = _FakeSharedContentReceiver(
      initialContent: _buildSharedImage(),
    );
    addTearDown(receiver.close);

    await tester.pumpWidget(
      RadarApplication(
        backendConfiguration: _unreachableServer,
        sharedContentReceiver: receiver,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analyse par intelligence artificielle'), findsOneWidget);

    await tester.tap(find.text('Rester hors-ligne'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Une image ne peut être lue qu'avec l'analyse IA autorisée (icône bouclier).",
      ),
      findsOneWidget,
    );
  });
}
