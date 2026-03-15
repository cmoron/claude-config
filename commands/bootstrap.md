---
description: Analyse le projet courant et génère un CLAUDE.md adapté. Usage : /bootstrap
allowed-tools: Read, Write, Bash, Glob, Grep
---
Analyse ce projet et génère un fichier `CLAUDE.md` à la racine.

Étapes :
1. Lire la structure (`find . -maxdepth 3 -type f | head -60`)
2. Détecter la stack principale :
   - `pyproject.toml` ou `uv.lock` → Python
   - `Cargo.toml` → Rust
   - `package.json` avec next → Next.js
3. Lire le README existant si présent
4. Regarder 3-5 fichiers source représentatifs pour comprendre les conventions
5. Regarder la config CI si présente (`.github/`, `Makefile`)

Génère un `CLAUDE.md` concis (~50-70 lignes) avec :
- Le contenu du snippet de stack correspondant (voir `~/src/claude-config/snippets/stack-<stack>.md`), copié verbatim
- Conventions observées dans le code (naming, structure)
- Pièges identifiés (si évidents)
- Fichiers importants à connaître

Crée aussi `tasks/lessons.md` s'il n'existe pas :
```markdown
# Lessons

Règles apprises après corrections — à relire en début de session.

<!-- Ajouter : date | contexte | règle -->
```

Ne pas inventer ce qui n'est pas visible dans le code.
