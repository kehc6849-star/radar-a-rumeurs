import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/analysis_history_entry.dart';
import '../../domain/repositories/analysis_history_repository.dart';

/// Keeps the history of results on the phone.
///
/// Only results are stored (level, score, date), never the analyzed content,
/// so this storage holds nothing that needs encryption.
class SharedPreferencesHistoryRepository implements AnalysisHistoryRepository {
  static const String _storageKey = 'analysis_history_v1';

  /// Keeps the list small so it stays fast and never grows without limit.
  static const int maximumEntryCount = 50;

  @override
  Future<List<AnalysisHistoryEntry>> loadEntries() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> storedLines =
        preferences.getStringList(_storageKey) ?? const <String>[];

    final List<AnalysisHistoryEntry> entries = <AnalysisHistoryEntry>[];

    for (final String storedLine in storedLines) {
      try {
        final AnalysisHistoryEntry? entry =
            AnalysisHistoryEntry.tryParse(jsonDecode(storedLine));

        if (entry != null) {
          entries.add(entry);
        }
      } on FormatException {
        // A damaged line is skipped: it must not hide the others.
        continue;
      }
    }

    return entries;
  }

  @override
  Future<void> addEntry(AnalysisHistoryEntry entry) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> storedLines =
        List<String>.of(preferences.getStringList(_storageKey) ?? const <String>[]);

    storedLines.insert(0, jsonEncode(entry.toJson()));

    if (storedLines.length > maximumEntryCount) {
      storedLines.removeRange(maximumEntryCount, storedLines.length);
    }

    await preferences.setStringList(_storageKey, storedLines);
  }

  @override
  Future<void> clearEntries() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }
}
