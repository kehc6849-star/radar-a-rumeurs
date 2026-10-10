import 'package:flutter/material.dart';

import '../../domain/models/detected_signal.dart';

/// Shows one detected signal with its plain-language explanation.
class DetectedSignalTile extends StatelessWidget {
  const DetectedSignalTile({super.key, required this.signal});

  final DetectedSignal signal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text(signal.title),
        subtitle: Text(signal.explanation),
      ),
    );
  }
}
