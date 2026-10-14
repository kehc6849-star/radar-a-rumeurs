import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/data/local/shared_preferences_ai_consent_repository.dart';
import 'package:radar_a_rumeurs/features/analysis/data/local/shared_preferences_history_repository.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/ai_consent_status.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_history_entry.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/threat_family.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesAiConsentRepository', () {
    test('is undecided by default and remembers the choice', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferencesAiConsentRepository repository =
          SharedPreferencesAiConsentRepository();

      expect(await repository.loadStatus(), AiConsentStatus.undecided);

      await repository.saveStatus(AiConsentStatus.granted);

      expect(await repository.loadStatus(), AiConsentStatus.granted);
    });

    test('asks again when the stored value is damaged', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ai_consent_status_v1': 'something-unknown',
      });

      expect(
        await SharedPreferencesAiConsentRepository().loadStatus(),
        AiConsentStatus.undecided,
      );
    });
  });

  group('SharedPreferencesHistoryRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('returns the newest entries first', () async {
      final SharedPreferencesHistoryRepository repository =
          SharedPreferencesHistoryRepository();

      await repository.addEntry(buildHistoryEntry(identifier: 'first'));
      await repository.addEntry(buildHistoryEntry(identifier: 'second'));

      final List<AnalysisHistoryEntry> entries = await repository.loadEntries();

      expect(
        entries.map((AnalysisHistoryEntry entry) => entry.identifier),
        <String>['second', 'first'],
      );
      expect(entries.first.primaryFamily, ThreatFamily.phishing);
    });

    test('keeps at most the maximum number of entries', () async {
      final SharedPreferencesHistoryRepository repository =
          SharedPreferencesHistoryRepository();

      for (int position = 0;
          position < SharedPreferencesHistoryRepository.maximumEntryCount + 5;
          position++) {
        await repository.addEntry(buildHistoryEntry(identifier: '$position'));
      }

      final List<AnalysisHistoryEntry> entries = await repository.loadEntries();

      expect(
        entries.length,
        SharedPreferencesHistoryRepository.maximumEntryCount,
      );
      expect(
        entries.first.identifier,
        '${SharedPreferencesHistoryRepository.maximumEntryCount + 4}',
      );
    });

    test('can be cleared', () async {
      final SharedPreferencesHistoryRepository repository =
          SharedPreferencesHistoryRepository();

      await repository.addEntry(buildHistoryEntry());
      await repository.clearEntries();

      expect(await repository.loadEntries(), isEmpty);
    });

    test('skips damaged lines and keeps the valid ones', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'analysis_history_v1': <String>[
          'not json at all',
          '{"identifier": 1}',
          jsonEncode(buildHistoryEntry(identifier: 'valid').toJson()),
        ],
      });

      final List<AnalysisHistoryEntry> entries =
          await SharedPreferencesHistoryRepository().loadEntries();

      expect(entries.single.identifier, 'valid');
    });

    test('never stores the analyzed content', () async {
      final Map<String, Object?> storedJson = buildHistoryEntry().toJson();

      expect(storedJson.keys, isNot(contains('text')));
      expect(storedJson.keys, isNot(contains('content')));
    });
  });
}
