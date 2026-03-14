---
description: Génère un commit message sémantique en analysant le diff. Usage : /commit
allowed-tools: Bash, Read
---
Analyse le diff courant et génère un commit message.

```bash
git diff --staged
git status --short
```

Si rien n'est staged, regarder tout le diff :
```bash
git diff HEAD
```

Format du commit message (Gitmoji + Conventional Commits) :
```
<emoji> <type>(<scope>): <description courte en français>

[Corps optionnel : explication du POURQUOI si non évident]
```

Gitmoji à utiliser :
- ✨ `feat` — nouvelle fonctionnalité
- 🐛 `fix` — correction de bug
- ♻️ `refactor` — refactoring sans changement de comportement
- 🧪 `test` — ajout ou correction de tests
- 📝 `docs` — documentation uniquement
- 🔧 `chore` — config, tooling, dépendances
- ⚡️ `perf` — amélioration de performance
- 💄 `style` — formatage, style (sans logique)
- 🗑️ `chore` — suppression de code/fichiers
- 🔒 `fix` — correctif de sécurité
- 🚀 `chore` — déploiement

Règles :
- Description < 72 caractères
- Présent de l'indicatif ("ajoute", "corrige", "supprime")
- Le corps explique le POURQUOI, pas le quoi (le diff montre le quoi)
- Pas de "wip" ni de "update" vagues

Propose le message et attends confirmation avant de committer.
