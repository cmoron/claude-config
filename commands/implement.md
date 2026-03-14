---
description: Implémente une feature complète avec tests. Usage : /implement <description de la feature>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---
Implémente : $ARGUMENTS

Workflow obligatoire dans cet ordre :
1. Explorer 2-3 fichiers similaires dans le projet pour comprendre les patterns
2. Écrire un plan en 3-5 étapes (TodoWrite)
3. Écrire les tests en premier
4. Implémenter le minimum pour faire passer les tests
5. Vérifier que tous les tests passent (`cargo test` / `pytest` / `pnpm test`)
6. Ne pas committer — je vérifierai le diff avant

Si un choix architectural est ambigu, poser une question avant de coder.
