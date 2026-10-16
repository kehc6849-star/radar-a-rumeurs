import 'screenshot_input.dart';

/// Something another app (for example a messaging app) shared with this app.
sealed class SharedContent {
  const SharedContent();
}

/// A text message shared by the user.
class SharedTextContent extends SharedContent {
  const SharedTextContent(this.text);

  final String text;
}

/// An image shared by the user, already checked and ready to be analyzed.
class SharedScreenshotContent extends SharedContent {
  const SharedScreenshotContent(this.screenshot);

  final ScreenshotInput screenshot;
}

/// The shared item cannot be used (too large, wrong format, unreadable).
///
/// The message is written for the user and is safe to show.
class SharedContentRejected extends SharedContent {
  const SharedContentRejected(this.message);

  final String message;
}