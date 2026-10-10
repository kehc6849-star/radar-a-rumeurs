import '../models/detected_signal.dart';
import '../models/normalized_content.dart';
import '../models/threat_family.dart';
import 'scam_detection_rule.dart';

/// Looks at the web addresses inside a message.
///
/// It only reads the text of the address. It never opens the link,
/// so the user stays safe and nothing is sent over the network.
class SuspiciousLinkRule implements ScamDetectionRule {
  const SuspiciousLinkRule();

  static final RegExp _linkPattern = RegExp(
    r'(https?://[^\s<>"]+|www\.[^\s<>"]+|\b(?:bit\.ly|tinyurl\.com|cutt\.ly|rb\.gy|is\.gd)/[^\s<>"]+)',
  );
  static final RegExp _schemePattern = RegExp(r'^https?://');
  static final RegExp _hostEndPattern = RegExp(r'[/?#]');
  static final RegExp _trailingPunctuationPattern = RegExp(r'[.,;:!?)\]]+$');
  static final RegExp _numericAddressPattern =
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
  static final RegExp _digitPattern = RegExp(r'\d');

  static const Set<String> _shortenerHostnames = <String>{
    'bit.ly',
    'tinyurl.com',
    'cutt.ly',
    'rb.gy',
    'is.gd',
  };

  /// Names that scammers like to imitate in fake addresses.
  static const List<String> _brandKeywords = <String>[
    'wave',
    'orange',
    'senelec',
    'wizall',
    'moneygram',
    'western',
  ];

  @override
  String get identifier => 'suspicious_link';

  @override
  List<DetectedSignal> evaluate(NormalizedContent content) {
    final Iterable<RegExpMatch> linkMatches =
        _linkPattern.allMatches(content.matchingText);

    if (linkMatches.isEmpty) {
      return const <DetectedSignal>[];
    }

    bool hasShortenedLink = false;
    bool hasNumericAddress = false;
    bool hasBrandImitation = false;
    bool hasInsecureConnection = false;

    for (final RegExpMatch linkMatch in linkMatches) {
      final String link = _removeTrailingPunctuation(linkMatch.group(0) ?? '');
      final String? hostname = _extractHostname(link);

      if (hostname == null) {
        continue;
      }

      hasShortenedLink = hasShortenedLink || _shortenerHostnames.contains(hostname);
      hasNumericAddress =
          hasNumericAddress || _numericAddressPattern.hasMatch(hostname);
      hasBrandImitation = hasBrandImitation || _looksLikeBrandImitation(hostname);
      hasInsecureConnection = hasInsecureConnection || link.startsWith('http://');
    }

    final List<DetectedSignal> detectedSignals = <DetectedSignal>[];

    if (hasShortenedLink) {
      detectedSignals.add(
        const DetectedSignal(
          ruleIdentifier: 'suspicious_link_shortened',
          title: 'Lien raccourci',
          explanation:
              "Un lien raccourci cache la vraie adresse du site. Les arnaqueurs l'utilisent pour masquer un faux site.",
          weight: 25,
          family: ThreatFamily.phishing,
        ),
      );
    }

    if (hasNumericAddress) {
      detectedSignals.add(
        const DetectedSignal(
          ruleIdentifier: 'suspicious_link_numeric_address',
          title: 'Adresse faite de chiffres',
          explanation:
              "Le lien pointe vers une suite de chiffres au lieu d'un nom de site. Les services sérieux n'envoient pas ce type de lien.",
          weight: 35,
          family: ThreatFamily.phishing,
        ),
      );
    }

    if (hasBrandImitation) {
      detectedSignals.add(
        const DetectedSignal(
          ruleIdentifier: 'suspicious_link_brand_imitation',
          title: 'Lien qui imite un service connu',
          explanation:
              "L'adresse contient le nom d'un service connu avec des ajouts (tirets, chiffres). C'est une technique courante des faux sites.",
          weight: 35,
          family: ThreatFamily.phishing,
        ),
      );
    }

    if (hasInsecureConnection) {
      detectedSignals.add(
        const DetectedSignal(
          ruleIdentifier: 'suspicious_link_insecure_connection',
          title: 'Connexion non sécurisée',
          explanation:
              "Le lien commence par « http » et non « https » : les données saisies ne sont pas protégées.",
          weight: 10,
          family: ThreatFamily.phishing,
        ),
      );
    }

    return detectedSignals;
  }

  String _removeTrailingPunctuation(String link) {
    return link.replaceAll(_trailingPunctuationPattern, '');
  }

  String? _extractHostname(String link) {
    final String linkWithoutScheme = link.replaceFirst(_schemePattern, '');
    final String hostAndPort = linkWithoutScheme.split(_hostEndPattern).first;
    final String hostname = hostAndPort.split(':').first;

    if (hostname.isEmpty) {
      return null;
    }

    return hostname;
  }

  bool _looksLikeBrandImitation(String hostname) {
    final bool containsBrandKeyword = _brandKeywords.any(
      (String brandKeyword) => hostname.contains(brandKeyword),
    );
    final bool hasImitationHint =
        hostname.contains('-') || _digitPattern.hasMatch(hostname);

    return containsBrandKeyword && hasImitationHint;
  }
}
