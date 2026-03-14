---
description: Analyse le projet courant et génère un CLAUDE.md adapté. Usage : /bootstrap
allowed-tools: Read, Write, Bash, Glob, Grep
---
Analyse ce projet et génère un fichier `CLAUDE.md` à la racine.

Étapes :
1. Lire la structure (`find . -maxdepth 3 -type f | head -60`)
2. Lire `Cargo.toml` / `package.json` / `pyproject.toml` si présents
3. Lire le README existant si présent
4. Regarder 3-5 fichiers source représentatifs pour comprendre les conventions
5. Regarder la config CI si présente (`.github/`, `Makefile`)

Génère un `CLAUDE.md` concis (~40-60 lignes) avec :
- Stack technique détectée (versions si disponibles)
- Commandes essentielles : dev, test, build, lint
- Conventions observées dans le code (naming, structure)
- Pièges identifiés (si évidents)
- Fichiers importants à connaître

Ne pas inventer ce qui n'est pas visible dans le code.
