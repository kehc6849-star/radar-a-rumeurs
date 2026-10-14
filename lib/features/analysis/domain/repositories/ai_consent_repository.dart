import '../models/ai_consent_status.dart';

/// Contract for remembering the choice of the user about the AI service.
abstract interface class AiConsentRepository {
  Future<AiConsentStatus> loadStatus();

  Future<void> saveStatus(AiConsentStatus status);
}
