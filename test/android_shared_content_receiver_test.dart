// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/data/device/android_shared_content_receiver.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/shared_content.dart';

const MethodChannel _nativeChannel = MethodChannel(
  AndroidSharedContentReceiver.channelName,
);

// Plays the role of the Android side of the channel.
void _setNativeHandler(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_nativeChannel, handler);
}

void _answerWith(Object? answer) {
  _setNativeHandler((MethodCall call) async => answer);
}

// Plays the Android side sending a new share while the app is open.
Future<void> _sendFromNative(String method, Object? arguments) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );

  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _nativeChannel.name,
    message,
    (ByteData? reply) {},
  );
}

Uint8List _buildJpegBytes({int length = 64}) {
  final Uint8List bytes = Uint8List(length);

  bytes[0] = 0xFF;
  bytes[1] = 0xD8;
  bytes[2] = 0xFF;

  return bytes;
}

String _readRejectionMessage(SharedContent? content) {
  expect(content, isA<SharedContentRejected>());

  return (content! as SharedContentRejected).message;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AndroidSharedContentReceiver receiver;

  setUp(() {
    receiver = AndroidSharedContentReceiver();
  });

  tearDown(() {
    receiver.close();
    _setNativeHandler(null);
  });

  test('gives a shared text, without the spaces around it', () async {
    _answerWith(<String, Object?>{
      'type': 'text',
      'text': '  Bonjour, voici un message.  ',
    });

    final SharedContent? content = await receiver.takeInitialContent();

    expect(content, isA<SharedTextContent>());
    expect((content! as SharedTextContent).text, 'Bonjour, voici un message.');
  });

  test('gives nothing when the app was opened normally', () async {
    _answerWith(null);

    expect(await receiver.takeInitialContent(), isNull);
  });

  test('gives the initial content only once', () async {
    int callCount = 0;

    _setNativeHandler((MethodCall call) async {
      callCount += 1;

      return <String, Object?>{'type': 'text', 'text': 'Premier message'};
    });

    final SharedContent? firstContent = await receiver.takeInitialContent();
    final SharedContent? secondContent = await receiver.takeInitialContent();

    expect(firstContent, isA<SharedTextContent>());
    expect(secondContent, isNull);
    expect(callCount, 1);
  });

  test('rejects an empty shared text with a clear message', () async {
    _answerWith(<String, Object?>{'type': 'text', 'text': '   '});

    final SharedContent? content = await receiver.takeInitialContent();

    expect(_readRejectionMessage(content), 'Le texte partagé est vide.');
  });

  test('rejects a shared text that is too long', () async {
    _answerWith(<String, Object?>{'type': 'text', 'text': 'a' * 5001});

    final SharedContent? content = await receiver.takeInitialContent();

    expect(_readRejectionMessage(content), contains('trop long'));
  });

  test('gives a shared image with its real format', () async {
    _answerWith(<String, Object?>{'type': 'image', 'bytes': _buildJpegBytes()});

    final SharedContent? content = await receiver.takeInitialContent();

    expect(content, isA<SharedScreenshotContent>());

    final ScreenshotInput screenshot =
        (content! as SharedScreenshotContent).screenshot;

    expect(screenshot.mimeType, 'image/jpeg');
    expect(screenshot.imageBytes.length, 64);
  });

  test('rejects a shared file that is not an image', () async {
    _answerWith(<String, Object?>{'type': 'image', 'bytes': Uint8List(64)});

    final SharedContent? content = await receiver.takeInitialContent();

    expect(_readRejectionMessage(content), contains("Format d'image"));
  });

  test('rejects a shared image that is too large', () async {
    _answerWith(<String, Object?>{
      'type': 'image',
      'bytes': _buildJpegBytes(length: ScreenshotInput.maximumImageBytes + 1),
    });

    final SharedContent? content = await receiver.takeInitialContent();

    expect(_readRejectionMessage(content), contains('trop volumineuse'));
  });

  test('rejects a content that Android could not read', () async {
    _answerWith(<String, Object?>{'type': 'unreadable'});

    final SharedContent? content = await receiver.takeInitialContent();

    expect(
      _readRejectionMessage(content),
      'Impossible de lire le contenu partagé.',
    );
  });

  test('rejects the content when the channel reports an error', () async {
    _setNativeHandler((MethodCall call) async {
      throw PlatformException(code: 'read_failed');
    });

    final SharedContent? content = await receiver.takeInitialContent();

    expect(
      _readRejectionMessage(content),
      'Impossible de lire le contenu partagé.',
    );
  });

  test('gives nothing when there is no Android side', () async {
    _setNativeHandler(null);

    expect(await receiver.takeInitialContent(), isNull);
  });

  test('sends a text shared while the app is already open', () async {
    final Future<SharedContent> nextContent =
        receiver.sharedContentStream.first;

    await _sendFromNative('contentReceived', <String, Object?>{
      'type': 'text',
      'text': 'Message reçu pendant que ouvert',
    });

    final SharedContent content = await nextContent;

    expect(content, isA<SharedTextContent>());
    expect(
      (content as SharedTextContent).text,
      'Message reçu pendant que ouvert',
    );
  });

  test('gives nothing after the receiver is closed', () async {
    _answerWith(<String, Object?>{'type': 'text', 'text': 'Trop tard'});

    receiver.close();

    expect(await receiver.takeInitialContent(), isNull);
  });
}
