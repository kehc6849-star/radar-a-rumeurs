# 10 — Travail en équipe

*État : version initiale. À ajuster avec l'équipe.*

Objectif : travailler en parallèle sans se bloquer, garder un historique Git propre et un `main` qui fonctionne toujours.

## 1. Règle d'or

> **`main` doit toujours passer `flutter analyze` et `flutter test`.**
> On ne travaille jamais directement dessus pour une fonctionnalité : on passe par une branche et une *pull request* (PR).

## 2. Répartition indicative (à adapter aux compétences)

| Zone | Dossiers principaux | Responsable |
|---|---|---|
| Interface et écrans | `lib/features/analysis/presentation`, `lib/core` | *à renseigner* |
| Moteur d'analyse, règles, tests | `lib/features/analysis/domain`, `test` | *à renseigner* |
| IA, service serveur, sécurité | `backend/` (à venir), configuration | *à renseigner* |
| Documentation, vidéo, soumission | `docs`, `README.md`, `CHANGELOG.md` | *à renseigner* |

Chacun reste en priorité dans sa zone : cela réduit fortement les conflits. Pour toucher la zone d'un autre, prévenez-le.

## 3. Cycle de travail quotidien

```bash
git switch main
git pull                       # récupérer le travail des autres
git switch -c feature/nom-court  # nouvelle branche pour votre tâche

# ... travail, puis :
flutter analyze && flutter test
git add <fichiers>
git commit -m "feat: description courte"
git push -u origin feature/nom-court
```

Ensuite, sur GitHub : **Compare & pull request**, décrire le *pourquoi*, attendre le feu vert de l'intégration continue, puis fusionner.

Avant de pousser une branche longue, récupérez les changements de `main` :
```bash
git fetch origin
git rebase origin/main
```
En cas de conflit : résolvez fichier par fichier, `git add`, puis `git rebase --continue`. Si vous hésitez, demandez de l'aide avant de forcer quoi que ce soit.

## 4. Conventions

**Branches** : `feature/...`, `fix/...`, `docs/...`, `test/...`.

**Messages de commit** (en anglais, courts, à l'impératif) :

| Préfixe | Usage |
|---|---|
| `feat:` | nouvelle fonctionnalité |
| `fix:` | correction |
| `docs:` | documentation |
| `test:` | tests |
| `refactor:` | réorganisation sans changer le comportement |
| `chore:` | outils, configuration |
| `ci:` | intégration continue |

**Fréquence** : petits commits, souvent. L'historique est lu par le jury.

## 5. Relecture

- Une relecture par un autre membre est **souhaitée** pour chaque PR.
- Si personne ne répond sous 24 heures, la PR peut être fusionnée par son auteur à condition que l'intégration continue soit verte. Le temps de chacun est limité.

## 6. Définition de « terminé »

- [ ] `flutter analyze` : aucun avertissement
- [ ] `flutter test` : tout passe
- [ ] Nouveau comportement couvert par un test
- [ ] Documentation mise à jour (`CHANGELOG.md`, `docs/`) si nécessaire
- [ ] Déclaration IA mise à jour si un modèle ou une API est ajouté ([03](03_AI_USAGE.md))

## 7. Ce qu'on ne publie JAMAIS

- Clés d'API, mots de passe, jetons : seulement dans un fichier `.env` local (ignoré par Git). Seul `.env.example` est publié.
- Vrais numéros de téléphone, noms ou identifiants dans des exemples d'arnaques : toujours anonymiser.
- Si un secret est publié par erreur : **le révoquer immédiatement** chez le fournisseur, puis prévenir l'équipe. Le supprimer du dernier commit ne suffit pas.

## 8. Identité Git de chaque membre

```bash
git config user.name "Prénom Nom"
git config user.email "ID+pseudo@users.noreply.github.com"
```
L'adresse « noreply » se trouve dans GitHub > Settings > Emails. Elle évite d'exposer l'adresse personnelle et relie les commits au bon profil.

## 9. Suivi des tâches

Utilisez les **Issues** GitHub (une par tâche) et référencez-les dans les PR (`Closes #12`). Étiquettes conseillées : `P0`, `P1`, `P2`, `bug`, `docs`.

## 10. Calendrier de gel

| Date | Règle |
|---|---|
| Jusqu'au 17 octobre | Développement normal |
| 18 octobre | **Gel du code** : seulement des corrections et de la documentation |
| 18 octobre | Étiquette `v1.0.0` posée sur `main`, vidéo enregistrée |
| 19 octobre | **Soumission** sur MLH |
