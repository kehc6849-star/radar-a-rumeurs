import 'package:flutter/material.dart';

import '../../domain/models/verdict_level.dart';

/// Label, color and icon used to display a verdict level.
class VerdictLevelStyle {
  const VerdictLevelStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

extension VerdictLevelPresentation on VerdictLevel {
  /// "No signal found" uses a neutral blue-grey on purpose, not green:
  /// green would suggest that the message is guaranteed safe.
  VerdictLevelStyle get style {
    return switch (this) {
      VerdictLevel.noSignalFound => const VerdictLevelStyle(
          label: 'Aucun signal détecté',
          color: Color(0xFF546E7A),
          icon: Icons.info_outline,
        ),
      VerdictLevel.suspicious => const VerdictLevelStyle(
          label: 'Message douteux',
          color: Color(0xFFEF6C00),
          icon: Icons.warning_amber_rounded,
        ),
      VerdictLevel.dangerous => const VerdictLevelStyle(
          label: 'Message dangereux',
          color: Color(0xFFC62828),
          icon: Icons.gpp_bad_outlined,
        ),
    };
  }
}
