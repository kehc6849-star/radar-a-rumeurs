# 04 — Règles de détection

*État : lot 1 + correctifs. Source de vérité : `lib/features/analysis/domain/rules/scam_rule_catalog.dart`.*

## Principe

Chaque règle repère un **signal** dans le message. Chaque signal a un **poids**. Le score de risque est la somme des poids (plafonnée à 100). Le texte est d'abord **normalisé** (minuscules, sans accents, espaces uniques).

Une règle à mots-clés combine des **groupes de motifs** : un seul motif suffit dans un groupe (OU), mais tous les groupes doivent correspondre (ET). Cela limite les fausses alertes : le mot « code » seul est inoffensif, « code » avec « envoyez-le-nous » ne l'est pas.

## Seuils

| Score | Niveau affiché |
|---|---|
| 0 à 19 | Aucun signal détecté (ou « Peu de signaux détectés » si des signaux faibles existent) |
| 20 à 44 | Douteux |
| 45 à 100 | Dangereux |

## Catalogue

| Identifiant | Famille | Poids | Ce que la règle repère |
|---|---|---|---|
| `one_time_code_request` | Mobile money | 45 | Demande de transmettre un code reçu par SMS |
| `personal_secret_request` | Mobile money | 50 | Demande de code secret ou de mot de passe |
| `mistaken_transfer_claim` | Mobile money | 45 | Faux « transfert par erreur » à renvoyer |
| `relative_number_change` | Mobile money | 45 | Faux proche avec « nouveau numéro » qui parle d'argent |
| `money_request_with_pretext` | Mobile money | 35 | Demande d'argent avec prétexte pressant |
| `provider_impersonation` | Mobile money | 15 | Se fait passer pour un service client |
| `artificial_urgency` | Hameçonnage | 15 | Pression du temps, menace de blocage |
| `prize_bait` | Hameçonnage | 35 | Faux gain ou cadeau |
| `account_verification_link` | Hameçonnage | 35 | « Cliquez pour vérifier ou débloquer votre compte » |
| `identity_document_request` | Hameçonnage | 40 | Demande de pièce d'identité ou de données personnelles |
| `english_scam_phrases` | Hameçonnage | 35 | Formules d'arnaque en anglais |
| `click_the_link_call_to_action` | Hameçonnage | 15 | Invitation à cliquer sur un lien |
| `scholarship_fee_request` | Fausse bourse | 50 | Bourse avec demande de paiement |
| `guaranteed_investment_promise` | Offre frauduleuse | 45 | Promesse de gains garantis |
| `job_or_visa_fee_request` | Offre frauduleuse | 40 | Frais demandés pour un emploi ou un visa |
| `chain_message_pressure` | Désinformation | 30 | Message à faire circuler à tout prix |
| `anonymous_insider_source` | Désinformation | 15 | « Un ami qui travaille à... » |
| `suspicious_link_shortened` | Hameçonnage | 25 | Lien raccourci |
| `suspicious_link_numeric_address` | Hameçonnage | 35 | Adresse faite de chiffres |
| `suspicious_link_brand_imitation` | Hameçonnage | 35 | Lien qui imite un service connu (nom + tiret ou chiffre) |
| `suspicious_link_insecure_connection` | Hameçonnage | 10 | Lien en `http` au lieu de `https` |

Les liens ne sont **jamais ouverts** : seule leur écriture est analysée.

## Limites connues

- **Faux positifs** : une phrase normale sur « les frais de visa » peut être classée « douteux ». Un simple « c'est urgent » reste sous le seuil d'alerte.
- **Faux négatifs** : un message formulé autrement que les motifs connus donne « aucun signal détecté ». C'est la raison d'être de l'analyse par IA (voir [feuille de route](07_ROADMAP.md)).
- **Langues** : français et anglais pour l'instant. Le wolof n'est pas encore couvert.

## Ajouter une règle

Voir [CONTRIBUTING.md](../CONTRIBUTING.md).
