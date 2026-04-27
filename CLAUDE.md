# Claude Code — Cyril Moron

## Principes
- Livraison itérative en tranches verticales (DB → API → UI)
- Comprendre avant de coder : explorer 2-3 fichiers similaires d'abord
- Tests avant ou avec le code — jamais après
- Git linéaire uniquement : rebase, pas de merge commits
- Conventional Commits — message = POURQUOI, pas le quoi

## Code quality
- Formatage automatique via hooks (ruff/rustfmt/prettier) — ne pas relancer manuellement
- Gestion d'erreurs explicite — pas de catch silencieux, pas de unwrap hors tests
- Un module = une responsabilité

## Toolchains
- Python : `uv` (gestion deps/envs), `ruff` (lint + format), `mypy` (types), `pytest`
  - CLI : `typer` (Click + type hints) + `rich` (output stylisé, tables, progress) par défaut
- JavaScript/TypeScript : `bun` uniquement (runtime, package manager, bundler, test runner) — pas de npm/pnpm/yarn/node

## Workflow
- Entrer en plan mode pour toute tâche 3+ étapes ou décision architecturale
- Sur un bug : diagnostiquer et corriger sans demander confirmation — pointer les logs, corriger
- Ne jamais déclarer une tâche terminée sans avoir prouvé qu'elle fonctionne
- Pause sur les changements non-triviaux : "existe-t-il une solution plus élégante ?"

## Agents custom
Agents spécialisés dans `~/.claude/agents/` (besoins non couverts par les plugins) :
- `software-architect` — choix de stack, ADR, conception macro (Opus)
- `fullstack-developer` — features complètes DB→API→UI
- `api-designer` — design REST/GraphQL, OpenAPI, versioning
- `ui-designer` — design system, composants, accessibilité
- `python-pro` — FastAPI, Pydantic, async, uv, ruff, mypy, pytest
- `rust-pro` — idiomes Rust, borrow checker, clippy

Bibliothèque de référence (141 agents) : `~/src/claude-config/upstream/awesome-claude-code-subagents/`
→ Si un nouveau besoin émerge, copier l'agent pertinent dans `agents/` et l'adapter avant de créer du custom.

Pour review / debug / audit / deploy / optimize / document : skills du plugin **`superpowers`**.

## Commandes slash custom
- `/commit` — génère un commit message sémantique (Conventional Commits)

Le reste (Plan, Architect, TDD, Debug, Review, Audit, Deploy, Document, Migrate…) est couvert par le plugin **`superpowers`**.
La maintenance auto du `CLAUDE.md` projet est couverte par **`claude-md-management`**.

## Outils de recherche (économie de tokens)
Ordre de préférence strict — ne JAMAIS utiliser le built-in Grep/Glob/WebSearch par défaut :

**Recherche de contenu**
1. `mgrep "query"` — sémantique, premier réflexe pour "trouve le code qui fait X"
2. `rg "pattern"` — recherche littérale/regex, gitignore-aware, SIMD (skip `node_modules`, binaires)
3. Built-in Grep tool — fallback uniquement si mgrep/rg indisponibles

**Recherche de fichiers**
- `fd "nom"` — remplace `find`, gitignore-aware, parallèle
- Built-in Glob — fallback

**Recherche par structure syntaxique (AST)**
- `ast-grep --pattern '...'` (alias `sg`) — pour patterns multi-lignes ou structurels impossibles en regex (ex: "async sans try/catch").

**Exploration de code avant lecture complète**
- Skill `claude-mem:smart-explore` — tree-sitter AST, retourne structure au lieu du fichier entier. À utiliser AVANT `Read` sur un fichier inconnu >200 lignes.

**Extraction structurée**
- `jq '.field'` pour JSON, `yq` pour YAML — extraire précisément, ne jamais `cat` un gros fichier structuré dans le contexte.

**Recherche web**
- `mgrep --web --answer "query"` — jamais le built-in WebSearch (trop verbeux, SERPs non résumées).

**Documentation de bibliothèques**
- Plugin `context7` — fetch doc à jour (React, FastAPI, etc.) avant de supposer une API.

## Gestion du contexte (plan Max, fenêtre 1M tokens)
- `/clear` entre deux tâches distinctes — toujours
- `/compact` à ~60% du contexte ou dès que le modèle oublie des instructions, en précisant quoi préserver : `/compact Keep: <décisions clés, fichiers en cours, contraintes>`
- Pour explorer du code : préférer un sous-agent (Explore) → résumé dans le contexte principal
- Ne jamais @-mentionner un gros fichier : indiquer le chemin + pourquoi le lire
- Mémoire cross-session : assurée par `claude-mem` (auto, MEMORY.md)

@RTK.md
