---
name: notion
description: Pour lire et enrichir la base documentaire DecaSaaS dans Notion. Contexte business, PRD, vision, rôles. MCP Notion actif — accès direct aux pages.
---

# Notion — Base documentaire DecaSaaS

Le MCP Notion est configuré globalement (`~/.claude/settings.json`, scope user).
Il est connecté au workspace **"Notion de Estelle Chauveau"**, espace **DecaSaaS**.

## Structure de l'espace DecaSaaS

```
DecaSaaS/                         (page racine — liens admin + ressources)
├── 🏢 Entreprise                 vision, rôles Cyril/Estelle, projets, outils
├── 🏃 MyPacer Club               PRD complet, stack, règles métier, roadmap
│   └── Pricing & pitch
├── 🔭 RetraiteZen                exploration, pas encore de stack
└── 💭 Brain storming             idées vrac
```

## IDs des pages clés

| Page | ID |
|------|----|
| DecaSaaS (racine) | `31d34197-b705-8057-80b8-fee9929f0898` |
| 🏢 Entreprise | `32c34197-b705-81a5-864b-d44771591fa8` |
| 🏃 MyPacer Club | `32b34197-b705-80bc-9399-ea226f0a08b3` |
| 🔭 RetraiteZen | `32c34197-b705-816e-96fb-de023a032646` |
| 💭 Brain storming | `32b34197-b705-8017-9a94-e338d200d611` |
| Pricing & pitch | `32434197-b705-80ba-86f3-d79ac0ac4dea` |

## Outils MCP disponibles

| Outil | Usage |
|-------|-------|
| `notion-search` | Recherche sémantique dans le workspace |
| `notion-fetch` | Lire une page ou base de données par ID/URL |
| `notion-create-pages` | Créer une ou plusieurs pages |
| `notion-update-page` | Modifier le contenu ou les propriétés d'une page |
| `notion-move-pages` | Déplacer des pages dans la hiérarchie |

## Conventions

- **Lire avant d'écrire** : toujours `notion-fetch` avant `notion-update-page`
- **Préserver les sous-pages** : lors d'un `replace_content`, inclure les tags `<page url="...">` existants ou utiliser `update_content` pour insérer sans écraser
- **Linear pour les tâches** : ne pas créer de tâches dans Notion — tout va dans Linear
- **Pas de suppression via MCP** : le MCP n'a pas d'outil delete — à faire manuellement dans Notion

## Reconnexion OAuth

Si le MCP n'est plus authentifié :
```
/mcp  → choisir "Notion de Estelle Chauveau" dans le sélecteur OAuth
```
