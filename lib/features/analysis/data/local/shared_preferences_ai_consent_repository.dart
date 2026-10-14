import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/ai_consent_status.dart';
import '../../domain/repositories/ai_consent_repository.dart';

/// Keeps the consent choice on the phone (a simple, non-sensitive setting).
class SharedPreferencesAiConsentRepository implements AiConsentRepository {
  static const String _storageKey = 'ai_consent_status_v1';

  @override
  Future<AiConsentStatus> loadStatus() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? storedName = preferences.getString(_storageKey);

    if (storedName == null) {
      return AiConsentStatus.undecided;
    }

    for (final AiConsentStatus status in AiConsentStatus.values) {
      if (status.name == storedName) {
        return status;
      }
    }

    // Unknown value (damaged data): ask the user again.
    return AiConsentStatus.undecided;
  }

  @override
  Future<void> saveStatus(AiConsentStatus status) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setString(_storageKey, status.name);
  }
}
