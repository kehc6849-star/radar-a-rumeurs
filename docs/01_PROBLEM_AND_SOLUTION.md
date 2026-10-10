# 01 — Problème et solution

*État : version initiale, à enrichir avec les retours des testeurs.*

## Le problème

Au Sénégal et en Afrique de l'Ouest, deux fléaux se renforcent :

1. **Les arnaques par message** : usurpation de comptes mobile money (Orange Money, Wave), faux « transferts par erreur », faux liens de vérification de compte, fausses offres de bourses d'études ou d'emploi.
2. **Les fausses informations** : rumeurs, images ou vidéos trompeuses, messages « à partager à tout prix ».

Ils circulent surtout par **WhatsApp**, sous forme de **vocaux** et de **captures d'écran**. Beaucoup de personnes n'ont ni le réflexe ni l'outil pour vérifier avant d'agir. Les outils de vérification existants sont en général en anglais et se limitent au texte.

## Les utilisateurs visés

- Utilisateurs de mobile money, y compris peu à l'aise avec le numérique.
- Étudiants qui cherchent une bourse.
- Familles qui reçoivent et transfèrent des messages.

## La solution

Une application mobile (Flutter) où l'utilisateur colle un message (puis, dans les prochains lots, partage une capture d'écran ou un vocal). L'application renvoie :

- un **verdict en trois niveaux** (aucun signal détecté / douteux / dangereux) ;
- la liste des **signaux repérés**, expliqués en français simple ;
- des **conseils d'action** adaptés au type de menace.

## Principes de conception

- **Jamais de « sûr »** : l'absence de signal ne prouve pas qu'un message est fiable.
- **Estimation, pas preuve** : les résultats sont des probabilités, avec un avertissement visible.
- **Confidentialité d'abord** : aucun message stocké ni envoyé dans la version actuelle.
- **Transparence** : chaque signal est expliqué, aucune « boîte noire » dans le moteur de règles.
- **Ouvert** : les règles sont publiques et chacun peut en proposer.

## Périmètre

| Dans le périmètre | Hors périmètre (assumé) |
|---|---|
| Texte collé, captures d'écran, vocaux | Détection fiable d'images ou vidéos générées par IA |
| Arnaques mobile money, fausses bourses, phishing | Analyse de vidéos longues |
| Rumeurs et messages en chaîne | Diagnostic juridique ou accompagnement des victimes |
| Conseils d'action | Blocage automatique d'appels ou de SMS |

Pour les images et vidéos, nous afficherons au mieux des **indices** (« indice, pas preuve »), jamais un verdict de détection.
