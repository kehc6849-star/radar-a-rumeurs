# 05 — Confidentialité et sécurité

*État : lot 2 (analyse locale + analyse IA facultative).*

## Deux modes

| Mode | Ce qui se passe |
|---|---|
| **Hors-ligne** (par défaut, ou si l'utilisateur refuse l'IA) | Tout reste sur le téléphone. Rien n'est envoyé. |
| **Avec IA** (après accord de l'utilisateur) | Le texte ou la capture est envoyé à notre serveur, puis à Gemma 4 via l'API Gemini, pour analyse. |

## Consentement

- Au premier lancement (si un serveur est configuré), un écran explique **ce qui est envoyé, à qui, et ce qui est conservé**. L'utilisateur peut refuser : l'analyse locale reste disponible.
- Fermer cet écran autrement que par « Autoriser » **compte comme un refus**.
- L'icône bouclier permet de changer d'avis à tout moment.
- Une capture d'écran ne peut jamais être envoyée sans accord.

## Ce qui est conservé, et où

| Donnée | Téléphone | Notre serveur | Fournisseur d'IA |
|---|---|---|---|
| Message ou capture analysé | Effacé au retour à l'accueil | **Non conservé, non journalisé** | Traité selon ses conditions (voir ci-dessous) |
| Résultat (niveau, score, date, type) | **Historique local** (50 entrées maximum, effaçable) | Cache en mémoire vive pendant 1 heure : seulement un hachage du message et le verdict | — |
| Texte lu dans une capture | En mémoire le temps de l'analyse | Non conservé | — |
| Compteurs techniques (type d'analyse, niveau, jetons, durée) | — | Journalisés, **sans contenu** | — |
| Choix de consentement | Réglage local | — | — |

L'historique ne contient **jamais** le contenu analysé : il ne peut donc pas révéler ce que l'utilisateur a reçu.

## Le fournisseur d'IA

Les conditions du fournisseur s'appliquent aux données qu'il reçoit. **Sur l'offre gratuite de l'API Gemini, le fournisseur peut utiliser les contenus envoyés pour améliorer ses produits** (à revérifier dans les conditions en vigueur). C'est écrit dans l'écran de consentement. En conséquence :
- l'application déconseille d'envoyer des données très sensibles (codes, mots de passe, pièces d'identité) ;
- les tests et la démonstration utilisent des **messages fictifs** ;
- les images sont envoyées **dans la requête** et non téléversées comme fichiers conservés.

## Principes de sécurité du code

- **Aucun secret dans le dépôt** : la clé d'API reste dans `backend/.env` (ignoré par Git) ; seul `backend/.env.example` est publié. L'application mobile ne contient aucune clé d'API.
- **Adresse du serveur** : fournie à la compilation (`--dart-define`), jamais écrite dans le code source.
- **Jeton d'accès optionnel** (`X-Radar-Access-Token`) : freine les abus occasionnels. Ce n'est pas un secret fort, puisqu'il est présent dans l'application.
- **Validation stricte des entrées** : texte nettoyé et borné ; images vérifiées sur leur **contenu réel** (JPEG, PNG, WebP), jamais sur le nom du fichier ; taille limitée.
- **Protection du quota** : limite par appareil et limite globale (voir [11](11_AI_QUOTAS_AND_LIMITS.md)).
- **Manipulation du modèle** : le message est traité comme une donnée non fiable et la réponse est vérifiée par du code (voir [03](03_AI_USAGE.md)).
- **Aucun journal de contenu** : ni sur le serveur, ni dans l'application. Les erreurs techniques sont masquées derrière des messages génériques.
- **Qualité** : analyse statique sans aucun avertissement, tests automatiques sur chaque modification (application et serveur).

## Limites

- Radar à Rumeurs fournit une **estimation**, pas une preuve.
- Le jeton d'accès contenu dans l'application peut être extrait par quelqu'un de motivé.
- Le cache et les limites de débit sont en mémoire : ils sont remis à zéro au redémarrage du serveur.
- La communication entre l'application et le serveur doit se faire en **HTTPS** en dehors des essais locaux.

## Signaler un problème de sécurité

Voir [SECURITY.md](../SECURITY.md).
