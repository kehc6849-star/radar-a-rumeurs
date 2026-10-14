import 'package:flutter/material.dart';

import 'app/radar_application.dart';
import 'core/configuration/backend_configuration.dart';

void main() {
  runApp(
    RadarApplication(
      backendConfiguration: BackendConfiguration.fromEnvironment(),
    ),
  );
}
