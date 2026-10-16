# 11 — Quotas et limites de l'IA (Gemma 4)

*État au 16 octobre 2026 : plan d'action du lot 2, mis à jour après le déploiement sur Render et les premiers essais sur téléphone. Les chiffres réels du compte (tableau section 2) restent à relever.*

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

**Ensuite, régler ces deux variables** (en local : fichier `backend/.env` ; sur Render : onglet **Environment** du service `radar-backend`, ce qui redémarre le service) :
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
| Hébergement Render (offre gratuite) | Le PC n'a plus besoin d'être allumé. Le service s'endort après 15 minutes sans requête et met environ 1 minute à se réveiller ; le cache et les compteurs de limites, qui sont en mémoire, sont remis à zéro à chaque endormissement ou redémarrage |

## 5. Ce que voit l'utilisateur

| Situation | Texte | Résultat |
|---|---|---|
| Quota Google épuisé ou serveur saturé (analyse de texte) | « L'analyse IA est très sollicitée en ce moment… » | Résultat des règles locales |
| Serveur ou réseau indisponible (analyse de texte) | « L'analyse IA est indisponible… » | Résultat des règles locales |
| Quota épuisé (capture d'écran) | « Réessayez dans une minute. » | Pas de résultat (l'image exige l'IA) |
| Erreur 500 de Google ou délai dépassé (capture d'écran) | « Le serveur d'analyse est indisponible pour le moment. Réessayez plus tard. » | Pas de résultat (l'image exige l'IA) |

## 6. Plan pour le jour de la démonstration

- [ ] **J-2** : relever les quotas du compte (section 2) et régler les variables (`.env` en local, onglet Environment sur Render).
- [ ] **J-2** : lancer 10 à 15 analyses d'essai et noter la consommation réelle de jetons.
- [ ] **J-1** : préparer **5 à 8 messages de démonstration fictifs** (jamais de vraies données personnelles) et les passer une fois pour remplir le cache. **Sur Render, le cache est vidé quand le service s'endort** : le remplir juste avant la démonstration, pas la veille.
- [ ] **Jour J, matin** : vérifier l'état du quota dans AI Studio ; ne **pas redémarrer** le serveur après avoir rempli le cache (il est en mémoire).
- [ ] **Avant la démonstration** : ne pas faire d'essais en rafale dans l'heure qui précède.
- [ ] **Juste avant la démonstration (Render)** : ouvrir `https://radar-backend-sqh2.onrender.com/health` environ 2 minutes avant pour réveiller le service, attendre `"aiConfigured":true`, puis passer les messages de démonstration pour remplir le cache.
- [ ] **Plan USB** : serveur local sur le PC (`uvicorn`), `adb reverse tcp:8000 tcp:8000`, application lancée avec `--dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000`. Aucun HTTPS ni hébergement nécessaires ; seul le PC a besoin d'Internet pour joindre Google.
- [ ] **Secours** : avoir une **deuxième clé** (autre projet, par exemple celui d'un coéquipier) prête à remplacer dans `.env` ; savoir que l'application fonctionne **sans IA** (règles locales) si tout échoue ; avoir la vidéo de démonstration enregistrée.
- [ ] Une **facturation** sur le projet lèverait les limites gratuites mais engage des frais et change les conditions d'usage des données : décision à prendre en connaissance de cause, après lecture des conditions et des tarifs.

## 7. Que faire quand l'IA répond « 429 » pendant le développement

1. Regarder la page d'utilisation d'AI Studio : quel modèle est saturé ?
2. Attendre la minute suivante (limite par minute) ou le lendemain (limite par jour).
3. Pour continuer à travailler : tester avec les règles locales seules (laisser `BACKEND_BASE_URL` vide) ou changer de modèle dans `.env` (`AI_MODEL`) ou, sur Render, dans la variable `AI_MODEL` de l'onglet Environment.
4. Ne jamais contourner la limite en multipliant les comptes : cela peut entraîner un blocage.

## 8. À améliorer si le temps le permet

- Compteur d'utilisation visible dans `/health` (nombre d'appels IA du jour, sans contenu).
- Cache persistant (hachages et verdicts uniquement) pour survivre à un redémarrage.
- Mise en file d'attente courte au lieu d'un refus immédiat.
- Réessayer une fois, puis passer au modèle de secours, quand Google répond 500 (cas des captures d'écran, section 9) ; régler le délai d'attente des requêtes avec image.
- Éviter l'endormissement du service Render le jour de la démonstration (par exemple en ouvrant `/health` régulièrement ; une solution automatique est à vérifier dans les conditions de Render).

## 9. Journal des incidents

### 16 octobre 2026 — erreur 500 de Google sur certaines captures d'écran

- **Ce qu'on a vu** : avec le serveur Render, certaines captures d'écran font attendre l'application plusieurs secondes, puis elle affiche « Le serveur d'analyse est indisponible pour le moment. Réessayez plus tard. » Les journaux du serveur montrent une réponse **500 Internal Server Error** de l'API Gemini pour le modèle `gemma-4-26b-a4b-it`, puis, environ 30 secondes plus tard, notre `POST /v1/analyze-image` répond **503**. Aucune autre réponse de Google n'est journalisée entre les deux. Les analyses de texte ne sont pas touchées.
- **Ce que ce n'est pas** : un dépassement de quota. Un quota atteint produit une erreur **429**, pas 500.
- **Ce que dit la documentation de Google** : l'erreur 500 est une erreur interne côté Google. Ses causes possibles sont un contexte d'entrée trop long, un incident en cours (page d'état de l'API Gemini) ou une requête trop lourde pour être traitée dans le délai. Les remèdes proposés sont de réduire l'entrée, de passer temporairement à un autre modèle ou d'allonger le délai d'attente du client.
- **Hypothèses à vérifier** (aucune n'est confirmée) : certaines captures produisent beaucoup de jetons d'image ; le modèle principal est instable ou lent avec des images ; notre serveur n'enchaîne pas assez vite sur le modèle de secours après une erreur 500, ou son délai d'attente est trop court. Il faut relire `backend/app/ai_provider.py` et `backend/app/analysis_service.py`.
- **À faire** : relever la taille (en Ko et en pixels) des captures qui échouent ; refaire un essai avec la même capture ; consulter la page d'état de l'API Gemini ; relire la gestion de l'erreur 500 et du modèle de secours dans le serveur.
- **Pour la démonstration** : utiliser des captures qui ont déjà réussi, et garder le texte collé comme chemin principal (il n'est pas touché).
