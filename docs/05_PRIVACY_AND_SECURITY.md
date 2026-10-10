# 05 — Confidentialité et sécurité

*État : lot 1 (analyse locale). À mettre à jour dès qu'un service externe est utilisé.*

## Données traitées

Les utilisateurs collent des messages qui peuvent contenir des informations sensibles (numéros, noms, montants, codes). Nous traitons ces données avec la plus grande prudence.

| Question | Réponse (version actuelle) |
|---|---|
| Le message est-il envoyé sur Internet ? | **Non.** L'analyse se fait entièrement sur le téléphone. |
| Le message est-il enregistré ? | **Non.** Il n'est ni stocké ni journalisé. |
| Combien de temps reste-t-il en mémoire ? | Le texte et le résultat sont effacés au retour à l'écran d'accueil. |
| Les liens sont-ils ouverts ? | **Non.** Seule leur écriture est analysée. |

## Quand l'IA sera ajoutée

- L'utilisateur sera **informé clairement** avant tout envoi d'un message à un service externe.
- Aucune clé d'API ne sera présente dans l'application mobile : elles seront gardées dans un service léger côté serveur et lues depuis des **variables d'environnement**.
- Le service serveur **ne conservera pas** le contenu des messages et ne le journalisera pas.
- Les captures d'écran seront traitées sans stockage durable.

## Principes de sécurité du code

- Aucun secret écrit en dur (identifiant, jeton, clé d'API). Le fichier `.env` est exclu du dépôt ; seul un modèle `.env.example` est publié.
- Validation des entrées avant tout traitement (message vide, trop long).
- Aucun affichage de données sensibles dans les journaux ou la console.
- Analyse statique sans aucun avertissement et tests automatiques sur chaque modification (intégration continue).

## Limites

- Radar à Rumeurs fournit une **estimation**, pas une preuve. Il ne garantit jamais qu'un message est sûr.
- Une règle trop large peut classer à tort un message légitime comme douteux.

## Signaler un problème de sécurité

Voir [SECURITY.md](../SECURITY.md).
