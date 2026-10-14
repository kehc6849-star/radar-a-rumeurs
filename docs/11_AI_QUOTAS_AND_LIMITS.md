# 11 — Quotas et limites de l'IA (Gemma 4)

*État : plan d'action initial, lot 2. À compléter avec les chiffres réels du compte (tableau section 2).*

Notre IA (Gemma 4 via l'API Gemini) est utilisée avec un compte gratuit. Les limites sont donc **le premier risque technique de la démonstration** : si le quota est épuisé pendant la finale, l'IA ne répond plus. Ce document explique comment nous l'évitons.

## 1. Les trois limites à connaître

| Limite | Signification | Effet quand elle est atteinte |
|---|---|---|
| Requêtes par minute (RPM) | Nombre d'appels autorisés en une minute | Erreur 429 |
| Jetons par minute (TPM) | Quantité de texte traitée en une minute | Erreur 429 |
| Requêtes par jour (RPD) | Nombre d'appels autorisés par jour | Erreur 429 jusqu'à la remise à zéro |

Une limite s'applique **par projet** et en général **par modèle** : le modèle de secours dispose donc de son propre quota.

## 2. Relever les chiffres réels de notre compte (à faire une fois)

Dans Google AI Studio, ouvrir la page de suivi de l'utilisation et des limites du projet (les libellés peuvent changer) et recopier :

| Modèle | RPM | TPM | RPD | Date du relevé |
|---|---|---|---|---|
| `gemma-4-26b-a4b-it` (principal) | *à renseigner* | *à renseigner* | *à renseigner* | |
| `gemma-4-31b-it` (secours) | *à renseigner* | *à renseigner* | *à renseigner* | |

**Ensuite, régler le fichier `backend/.env`** :
- `GLOBAL_REQUESTS_PER_MINUTE` : légèrement **sous** le RPM du modèle principal ;
- `CLIENT_REQUESTS_PER_MINUTE` : environ la moitié de la valeur globale.

## 3. Coût approximatif d'un appel (estimation à mesurer)

| Élément | Ordre de grandeur |
|---|---|
| Instructions envoyées au modèle | environ 650 jetons |
| Message de l'utilisateur (3 000 caractères maximum envoyés) | jusqu'à environ 900 jetons |
| Réponse du modèle (plafonnée à 900 jetons) | 300 à 900 jetons |
| Image | à mesurer (dépend de la taille) |

Soit **environ 1 500 à 2 500 jetons par analyse de texte**. Ce sont des estimations : le serveur journalise le nombre réel de jetons de chaque appel (`tokens=` dans les journaux, **jamais le contenu**). Après quelques essais, remplacer l'estimation par la mesure.

**Capacité journalière estimée** = RPD du compte (le TPM est en général atteint plus tard). Elle sera calculée une fois les chiffres du compte relevés.

## 4. Mesures déjà intégrées au code

| Mesure | Effet |
|---|---|
| Règles locales d'abord, IA en complément | L'application reste utile même quand l'IA est indisponible |
| Repli automatique | Erreur 429, panne ou absence de réseau : le résultat des règles locales est affiché avec une note claire |
| Cache en mémoire (1 heure) | Le même message ne consomme pas deux fois le quota. La clé est un hachage du message : le texte n'est jamais conservé |
| Limite par appareil (par défaut 10 par minute) | Un seul utilisateur ne peut pas vider le quota |
| Limite globale (par défaut 12 par minute) | Le serveur refuse proprement avant que Google ne refuse |
| Modèle de secours `gemma-4-31b-it` | Utilisé automatiquement si le principal est saturé ou indisponible |
| Sortie plafonnée à 900 jetons, réflexion « minimal » | Réponses plus rapides et moins coûteuses |
| Texte envoyé à l'IA limité à 3 000 caractères | Borne le coût d'un message |
| Images réduites (1 600 px, qualité 85) et limitées à 4 Mo | Moins de jetons, envoi plus rapide |
| Image envoyée dans la requête (pas de fichier stocké) | Rien ne reste chez le fournisseur sous forme de fichier |

## 5. Ce que voit l'utilisateur

| Situation | Texte | Résultat |
|---|---|---|
| Quota Google épuisé ou serveur saturé (analyse de texte) | « L'analyse IA est très sollicitée en ce moment… » | Résultat des règles locales |
| Serveur ou réseau indisponible (analyse de texte) | « L'analyse IA est indisponible… » | Résultat des règles locales |
| Quota épuisé (capture d'écran) | « Réessayez dans une minute. » | Pas de résultat (l'image exige l'IA) |

## 6. Plan pour le jour de la démonstration

- [ ] **J-2** : relever les quotas du compte (section 2) et régler le `.env`.
- [ ] **J-2** : lancer 10 à 15 analyses d'essai et noter la consommation réelle de jetons.
- [ ] **J-1** : préparer **5 à 8 messages de démonstration fictifs** (jamais de vraies données personnelles) et les passer une fois pour remplir le cache.
- [ ] **Jour J, matin** : vérifier l'état du quota dans AI Studio ; ne **pas redémarrer** le serveur après avoir rempli le cache (il est en mémoire).
- [ ] **Avant la démonstration** : ne pas faire d'essais en rafale dans l'heure qui précède.
- [ ] **Secours** : avoir une **deuxième clé** (autre projet, par exemple celui d'un coéquipier) prête à remplacer dans `.env` ; savoir que l'application fonctionne **sans IA** (règles locales) si tout échoue ; avoir la vidéo de démonstration enregistrée.
- [ ] Une **facturation** sur le projet lèverait les limites gratuites mais engage des frais et change les conditions d'usage des données : décision à prendre en connaissance de cause, après lecture des conditions et des tarifs.

## 7. Que faire quand l'IA répond « 429 » pendant le développement

1. Regarder la page d'utilisation d'AI Studio : quel modèle est saturé ?
2. Attendre la minute suivante (limite par minute) ou le lendemain (limite par jour).
3. Pour continuer à travailler : tester avec les règles locales seules (laisser `BACKEND_BASE_URL` vide) ou changer de modèle dans `.env` (`AI_MODEL`).
4. Ne jamais contourner la limite en multipliant les comptes : cela peut entraîner un blocage.

## 8. À améliorer si le temps le permet

- Compteur d'utilisation visible dans `/health` (nombre d'appels IA du jour, sans contenu).
- Cache persistant (hachages et verdicts uniquement) pour survivre à un redémarrage.
- Mise en file d'attente courte au lieu d'un refus immédiat.
