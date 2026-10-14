import '../models/verdict_level.dart';

/// The sentence shown under the verdict, by level.
class VerdictSummaryCatalog {
  const VerdictSummaryCatalog._();

  static String buildSummary(VerdictLevel verdictLevel) {
    return switch (verdictLevel) {
      VerdictLevel.dangerous =>
        "Ce message réunit plusieurs caractéristiques typiques d'une arnaque. Ne répondez pas et ne cliquez sur aucun lien.",
      VerdictLevel.suspicious =>
        "Ce message contient des éléments inhabituels. Vérifiez par un canal officiel avant d'agir.",
      VerdictLevel.noSignalFound =>
        "Aucun signal d'arnaque connu n'a été détecté. Cela ne garantit pas que le message soit fiable : en cas de doute, vérifiez la source.",
    };
  }
}
