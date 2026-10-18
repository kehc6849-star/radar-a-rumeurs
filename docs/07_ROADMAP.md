# 07 — Feuille de route

*Dernière mise à jour : 18 octobre 2026.*

## Dates clés du hackathon

| Date | Étape |
|---|---|
| 7 octobre 2026 | Lancement |
| **19 octobre 2026** | **Soumission des projets** |
| 21 octobre 2026 | Présélection des 5 finalistes |
| 24 octobre 2026 | Finale à Impact Hub Dakar |

## Priorités

**P0 — obligatoire**
- [x] Squelette Flutter en couches, licence, README, intégration continue
- [x] Analyse de texte collé par règles locales
- [x] Écran de résultat : verdict, signaux, conseils
- [x] Tests unitaires et d'écran
- [x] Documentation complète (ce dossier)
- [x] Analyse par IA d'un texte (Gemma 4) avec repli sur les règles locales
- [x] Lecture et analyse de captures d'écran (Gemma 4)
- [x] Service serveur léger (clé d'API hors de l'application)
- [x] Écran de consentement avant tout envoi à l'IA
- [x] Historique local sans contenu
- [x] Déploiement du serveur en HTTPS (Render, offre gratuite) pour la démonstration

**P1**
- [x] Partage depuis une autre application vers l'application (image ou texte, menu « Partager » et menu de sélection de texte, Android)
- [x] Interface avec mode sombre
- [x] Icône de l'application
- [ ] Après la version 1.0 : partage direct d'un texte depuis WhatsApp (aujourd'hui, le texte se copie puis se colle)
- [ ] Après la version 1.0 : fiabiliser l'analyse des images lourdes, relever les quotas du compte Gemma, appliquer la rotation des photos partagées

**P2**
- [ ] Analyse approfondie des liens
- [ ] Base ouverte de motifs d'arnaques, alimentée par la communauté

**Hors périmètre assumé**
- Analyse de vocaux (transcription) : l'analyse audio n'est pas confirmée par l'API (décision du 16 octobre 2026)
- Hébergement GPU Brev : abandonné (décision du 16 octobre 2026)
- Détection fiable d'images ou vidéos générées par IA (indices seulement)
- Analyse de vidéos longues

## Lots de travail

| Lot | Contenu | État |
|---|---|---|
| 1 | Moteur local, écrans, tests | ✅ Fait |
| 1.1 | Correctifs et nouveaux motifs | ✅ Fait |
| 2 | Service serveur léger, IA (texte et captures), consentement, historique | ✅ Fait (validé sur téléphone le 15 octobre) |
| 3 | Déploiement du serveur, partage depuis une autre application, renommage final | ✅ Fait (vocaux abandonnés : hors périmètre) |
| 4 | Finitions, README final, vidéo de démonstration, soumission | 🔄 En cours (soumission le 19 octobre) |
