---
description: Revue du diff actuel (staged + unstaged). Usage : /review [focus]
allowed-tools: Read, Bash, Glob, Grep
---
Fais une revue complète du diff en cours :

```bash
git diff HEAD
git diff --staged
```

Si le diff est vide, regarder les derniers commits :
```bash
git log --oneline -5
git show HEAD
```

Focus optionnel : $ARGUMENTS (ex: "security", "performance", "tests")

Analyse par priorité décroissante :
1. Sécurité et data integrity
2. Correctness (bugs, edge cases)
3. Performance (O(n²) cachés, N+1 queries)
4. Lisibilité et maintenabilité

Pour chaque problème critique, fournis le code corrigé.
Pour les suggestions, une ligne suffit.
