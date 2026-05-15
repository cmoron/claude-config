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

## Agents custom
**Principe : les skills portent les compétences, les agents définissent les
métiers.** Une spécialisation de langage ou une technique (Python, Rust, design
d'API) est une compétence → skill (`stack-python`, `stack-rust`, `stack-ts`,
`api-design`), pas un agent.

Agents (métiers) spécialisés dans `~/.claude/agents/` :
- `software-architect` — choix de stack, ADR, conception macro (Opus)
- `fullstack-developer` — features complètes DB→API→UI

→ Si un nouveau besoin émerge, s'inspirer de la bibliothèque VoltAgent
([awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)),
copier l'agent pertinent dans `agents/` et l'adapter avant de créer du custom.

Pour review / debug / audit / optimize / document : skills du plugin **`superpowers`**.
Pour le déploiement : skill custom **`deployment`** (CI/CD GitHub Actions, Docker).

## Échelle d'effort — quand utiliser quel process

Calibrer le process au coût réel de la tâche. **Ne jamais sur-dimensionner.** Sur-process = tokens gaspillés et frustration utilisateur.

| Taille tâche | Signaux | Process |
|---|---|---|
| **XS** (≤30 min) | bug fix, typo, single fn, config | Direct. Pas de plan, pas de skill superpowers. Diagnostiquer → corriger → tester → commit. |
| **S** (≤2h) | 1 feature simple sur 1 couche, ≤3 fichiers, scope clair | Plan inline conversationnel (3-5 bullets), exécution directe, tests + commit. Pas de `brainstorming`, pas de `writing-plans`. |
| **M** (≤1 jour) | 1 feature mid-complexity, plusieurs couches OU plusieurs fichiers, décisions UX/API à arbitrer | `superpowers:brainstorming` (questions cadrage) → plan **court** (< 300 lignes) → exécution inline avec 1 review final. Pas de subagent-driven. |
| **L** (multi-jours) | feature traversant DB+API+UI, refactor, migration, multi-équipe | Full superpowers : `brainstorming` → `writing-plans` → `subagent-driven-development` → reviews. C'est conçu pour ça. |
| **XL** (semaines) | refonte architecturale, choix de stack | `software-architect` agent + ADR + décomposition en sous-projets, chacun traité comme L. |

**Règle d'or** : si je m'apprête à proposer `subagent-driven-development` pour <8h de dev estimé, **stop**. Demander confirmation explicite à l'utilisateur en exposant le coût (tokens, temps wallclock) attendu.

**Anti-patterns à éviter** :
- Plan de 1500+ lignes pour une feature qui tient en 1 PR — surplomb démesuré
- 1 spec + 1 plan + 6 subagents implémenteurs + 6 reviewers pour du CRUD basique
- Dispatcher un subagent pour une édition de 3 lignes — pollution context > économie
- Proposer un refactor de stack sans vérifier qu'une abstraction interne ne résoudrait pas l'essentiel de la friction

## Commandes slash custom
- `/commit` — génère un commit message sémantique (Conventional Commits)

Le reste (Plan, Architect, TDD, Debug, Review, Audit, Document, Migrate…) est couvert par le plugin **`superpowers`** — calibrer le niveau de process selon l'échelle ci-dessus.
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
