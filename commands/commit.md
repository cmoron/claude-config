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

Format du commit message (Conventional Commits) :
```
<type>(<scope>): <description courte en français>

[Corps optionnel : explication du POURQUOI si non évident]
```

Types : `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`

Règles :
- Description < 72 caractères
- Présent de l'indicatif ("ajoute", "corrige", "supprime")
- Le corps explique le POURQUOI, pas le quoi (le diff montre le quoi)
- Pas de "wip" ni de "update" vagues

Propose le message et attends confirmation avant de committer.
