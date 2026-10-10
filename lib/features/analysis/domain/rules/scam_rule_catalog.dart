import '../models/threat_family.dart';
import 'keyword_combination_rule.dart';
import 'scam_detection_rule.dart';
import 'suspicious_link_rule.dart';

/// Verbs used to ask someone to hand over or type a secret.
/// All patterns are written for normalized text (no accents, lower case).
const String _shareVerbPattern =
    r'\b(envoy(er|ez|e)|donn(er|ez|e)|communiqu(er|ez|e)|partag(er|ez|e)|transmet(tre|tez|s)?|dict(er|ez|e)|fournir|fournissez|saisi(r|ssez)|entr(er|ez)|confirm(er|ez))\b';

/// The list of detection rules shipped with the application.
///
/// To add a rule, add an entry here: no other file needs to change.
class ScamRuleCatalog {
  const ScamRuleCatalog._();

  static List<ScamDetectionRule> buildDefaultRules() {
    return <ScamDetectionRule>[
      KeywordCombinationRule(
        identifier: 'one_time_code_request',
        family: ThreatFamily.mobileMoneyFraud,
        title: 'Demande de code reçu par SMS',
        explanation:
            "Le message demande de transmettre un code de confirmation. Ce code donne accès à votre compte : aucun service sérieux ne le demande.",
        weight: 45,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\bcode\b.{0,40}\b(recu|sms|confirmation|validation|verification)\b'),
            RegExp(r'\b(recu|sms|confirmation|validation|verification)\b.{0,40}\bcode\b'),
            RegExp(r'\botp\b'),
          ],
          <RegExp>[RegExp(_shareVerbPattern)],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'personal_secret_request',
        family: ThreatFamily.mobileMoneyFraud,
        title: 'Demande de code secret ou de mot de passe',
        explanation:
            "Le message demande un code secret ou un mot de passe. Personne n'a le droit de vous le demander, pas même un opérateur ou une banque.",
        weight: 50,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(code secret|mot de passe|code pin|pin|code d.acces)\b'),
          ],
          <RegExp>[RegExp(_shareVerbPattern)],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'mistaken_transfer_claim',
        family: ThreatFamily.mobileMoneyFraud,
        title: 'Faux « transfert par erreur »',
        explanation:
            "L'expéditeur dit avoir envoyé de l'argent par erreur et demande de le renvoyer. C'est une arnaque très répandue : le transfert initial est souvent faux ou réversible.",
        weight: 45,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[RegExp(r'\bpar erreur\b')],
          <RegExp>[
            RegExp(r'\b(renvoy\w*|rembours\w*|retourn\w*|rend(re|ez)|restitu\w*|redonn\w*)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'provider_impersonation',
        family: ThreatFamily.mobileMoneyFraud,
        title: "Se fait passer pour un service client",
        explanation:
            "Le message prétend venir du service client d'un opérateur ou d'une banque. Les arnaqueurs usurpent ces noms pour inspirer confiance.",
        weight: 15,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(service client|service clientele|support technique|assistance)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(wave|orange money|orange|free money|wizall|moov money|banque)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'artificial_urgency',
        family: ThreatFamily.phishing,
        title: 'Pression du temps',
        explanation:
            "Le message crée une urgence ou menace de bloquer un compte. Cette pression sert à vous empêcher de réfléchir ou de vérifier.",
        weight: 15,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(urgent|urgence|immediatement|sans delai|dernier delai|derniere chance)\b'),
            RegExp(r'\bdans les \d+ ?(h|heures?|minutes?)\b'),
            RegExp(r'\bavant (ce soir|minuit|demain)\b'),
            RegExp(r'\b(sera|seront|va etre|vont etre) (definitivement )?(bloque|suspendu|ferme|desactive|supprime)\w*'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'prize_bait',
        family: ThreatFamily.phishing,
        title: 'Faux gain ou cadeau',
        explanation:
            "Le message annonce que vous avez gagné quelque chose. Si vous n'avez participé à rien, c'est un appât pour obtenir vos informations ou votre argent.",
        weight: 35,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(vous avez gagne|felicitations|tirage au sort|loterie|gagnant|gagnante)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'scholarship_fee_request',
        family: ThreatFamily.scholarshipScam,
        title: "Frais demandés pour une bourse d'études",
        explanation:
            "Le message parle d'une bourse et demande un paiement (frais de dossier, caution...). Les fausses offres de bourses vivent de ces frais.",
        weight: 50,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[RegExp(r'\b(bourse|bourses|scholarship)\b')],
          <RegExp>[
            RegExp(r'\b(frais|pay(er|ez|ement)|verser|versez|versement|caution)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'chain_message_pressure',
        family: ThreatFamily.misinformation,
        title: 'Message à faire circuler',
        explanation:
            "Le message insiste pour être partagé à un maximum de personnes. Les rumeurs et les fausses informations utilisent presque toujours cette technique.",
        weight: 30,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(partagez|partager|diffusez|diffuser|transferez|transferer|faites circuler)\b.{0,60}\b(tous vos contacts|vos contacts|vos proches|maximum de personnes|un maximum|vos groupes)\b'),
            RegExp(r'\bavant qu.?(ils|on) (ne )?(le|la|les) supprime'),
            RegExp(r'\b(info|information) (urgente|exclusive)\b'),
            RegExp(r'\bmessage a diffuser\b'),
            RegExp(r'\bpartagez (ce message|cette video|cette info|cette information)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'anonymous_insider_source',
        family: ThreatFamily.misinformation,
        title: 'Source anonyme',
        explanation:
            "L'information vient d'« un ami qui travaille quelque part ». Une source impossible à vérifier ne prouve rien.",
        weight: 15,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(un ami|un cousin|un proche|quelqu.un)\b.{0,30}\b(travaille|bosse)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'relative_number_change',
        family: ThreatFamily.mobileMoneyFraud,
        title: 'Faux proche avec un nouveau numéro',
        explanation:
            "Quelqu'un dit être un proche qui a changé de numéro et parle d'argent. C'est une arnaque classique : appelez l'ancien numéro de votre proche pour vérifier.",
        weight: 45,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(nouveau numero|numero a change|change de numero|changer de numero|mon ancien numero)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(argent|credit|recharge|transfert|envoie[rz]?|envoy(er|ez)|depos(er|ez)|\d[\d .,]*\s?(f|fcfa|cfa|xof))\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'money_request_with_pretext',
        family: ThreatFamily.mobileMoneyFraud,
        title: "Demande d'argent avec un prétexte pressant",
        explanation:
            "Le message demande d'envoyer de l'argent en invoquant une urgence (accident, hôpital, blocage). Vérifiez toujours par un appel direct avant d'envoyer quoi que ce soit.",
        weight: 35,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(envoy(er|ez|e)|transfer(er|ez|e)|depos(er|ez|e)|verse[rz]?)\b.{0,50}\b(\d[\d .,]*\s?(f|fcfa|cfa|xof)|argent|credit|recharge)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(urgent|urgence|accident|hopital|malade|bloque|coince|svp|s.il (te|vous) plait)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'account_verification_link',
        family: ThreatFamily.phishing,
        title: 'Lien pour « vérifier » ou « débloquer » un compte',
        explanation:
            "Le message demande de cliquer pour vérifier, mettre à jour ou débloquer un compte. C'est la méthode classique des faux sites qui volent vos identifiants.",
        weight: 35,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(compte|carte|numero|ligne|wave|orange money|banque)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(cliquez|clique|ouvrez le lien|via le lien|ce lien|le lien ci-dessous|lien suivant)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(verifi\w*|mettre a jour|mise a jour|debloqu\w*|reactiv\w*|confirm\w*|valid\w*|securis\w*)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'identity_document_request',
        family: ThreatFamily.phishing,
        title: "Demande de pièce d'identité ou de données personnelles",
        explanation:
            "Le message demande une pièce d'identité, un numéro de carte ou une date de naissance. Ces informations servent à usurper votre identité ou votre compte.",
        weight: 40,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(numero de (piece|carte)|carte d.identite|cni|passeport|date de naissance|photo de (votre )?(piece|carte)|numero de carte)\b'),
          ],
          <RegExp>[RegExp(_shareVerbPattern)],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'guaranteed_investment_promise',
        family: ThreatFamily.fraudulentOffer,
        title: 'Promesse de gains garantis',
        explanation:
            "Le message promet de doubler ou de faire fructifier votre argent rapidement. Un gain garanti sans risque n'existe pas : c'est le principe des fausses plateformes d'investissement.",
        weight: 45,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(double(z|r)? (votre )?(argent|mise)|gains? garanti\w*|investissez|investissement|rendement)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(\d+ ?%|garanti\w*|par jour|par semaine|rapidement|sans risque)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'job_or_visa_fee_request',
        family: ThreatFamily.fraudulentOffer,
        title: "Frais demandés pour un emploi ou un visa",
        explanation:
            "Le message parle d'un emploi, d'un visa ou d'un voyage et demande un paiement à l'avance. Les employeurs et les administrations sérieux ne fonctionnent pas ainsi.",
        weight: 40,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(emploi|recrutement|embauche|visa|contrat de travail|offre d.emploi|voyage)\b'),
          ],
          <RegExp>[
            RegExp(r'\b(frais|pay(er|ez|ement)|verser|versez|versement|caution|depot)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'english_scam_phrases',
        family: ThreatFamily.phishing,
        title: "Formules d'arnaque en anglais",
        explanation:
            "Le message utilise des formules typiques des arnaques par message (gain, vérification de compte, lien à ouvrir).",
        weight: 35,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\byou (have|ve) won\b'),
            RegExp(r'\bclaim your (prize|reward|gift)\b'),
            RegExp(r'\bverify your (account|identity|details)\b'),
            RegExp(r'\byour account (has been|will be) (suspended|blocked|locked|closed)\b'),
            RegExp(r'\bsend (me )?the (code|otp)\b'),
          ],
        ],
      ),
      KeywordCombinationRule(
        identifier: 'click_the_link_call_to_action',
        family: ThreatFamily.phishing,
        title: 'Invitation à cliquer sur un lien',
        explanation:
            "Le message pousse à cliquer sur un lien. Ouvrez plutôt l'application officielle du service concerné.",
        weight: 15,
        requiredPatternGroups: <List<RegExp>>[
          <RegExp>[
            RegExp(r'\b(cliquez|clique) (sur|ici)\b'),
            RegExp(r'\bclick (here|the link|on the link)\b'),
          ],
        ],
      ),
      const SuspiciousLinkRule(),
    ];
  }
}
