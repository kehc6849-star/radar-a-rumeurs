# 07 — Feuille de route

*Dernière mise à jour : 12 octobre 2026.*

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
- [ ] Documentation complète (ce dossier)
- [x] Analyse par IA d'un texte (Gemma 4) avec repli sur les règles locales
- [x] Lecture et analyse de captures d'écran (Gemma 4)
- [x] Service serveur léger (clé d'API hors de l'application)
- [x] Écran de consentement avant tout envoi à l'IA
- [x] Historique local sans contenu
- [ ] Déploiement du serveur en HTTPS (pour la démonstration)

**P1**
- [ ] Analyse de vocaux (transcription) — dépend de la prise en charge de l'audio par le modèle via l'API
- [ ] Partage direct depuis WhatsApp vers l'application

**P2**
- [ ] Analyse approfondie des liens
- [ ] Base ouverte de motifs d'arnaques, alimentée par la communauté

**Hors périmètre assumé**
- Détection fiable d'images ou vidéos générées par IA (indices seulement)
- Analyse de vidéos longues

## Lots de travail

| Lot | Contenu | État |
|---|---|---|
| 1 | Moteur local, écrans, tests | ✅ Fait |
| 1.1 | Correctifs et nouveaux motifs | ✅ Fait |
| 2 | Service serveur léger, IA (texte et captures), consentement, historique | ✅ Fait (à valider sur téléphone) |
| 3 | Déploiement du serveur, partage WhatsApp, renommage final, vocaux si possible | 🔜 |
| 4 | Finitions, README final, vidéo de démonstration, soumission | 🔜 |
