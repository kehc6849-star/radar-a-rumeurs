import 'package:flutter/material.dart';

import 'app/radar_application.dart';
import 'core/configuration/backend_configuration.dart';
import 'features/analysis/data/device/android_shared_content_receiver.dart';

void main() {
  // The receiver talks to Android, so the Flutter binding must exist first.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    RadarApplication(
      backendConfiguration: BackendConfiguration.fromEnvironment(),
      sharedContentReceiver: AndroidSharedContentReceiver(),
    ),
  );
}
