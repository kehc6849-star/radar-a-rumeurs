import '../models/analysis_history_entry.dart';

/// Contract for the history of results (never the analyzed content).
abstract interface class AnalysisHistoryRepository {
  /// Newest entries first.
  Future<List<AnalysisHistoryEntry>> loadEntries();

  Future<void> addEntry(AnalysisHistoryEntry entry);

  Future<void> clearEntries();
}
