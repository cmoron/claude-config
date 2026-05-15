# Réorganisation agents/skills (Lot B) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extraire les conventions de stack piégées dans des agents vers des skills compétences, et réduire les agents custom aux seuls métiers.

**Architecture:** Principe « skills = compétences, agents = métiers ». On crée 4 skills custom (`stack-python`, `stack-ts`, `stack-rust`, `api-design`), on supprime 3 agents (`python-pro`, `rust-pro`, `api-designer`), on recâble `fullstack-developer`, on synchronise la doc. Aucun plugin, aucun hook — déploiement par symlink via `install.sh` (mécanisme existant).

**Tech Stack:** Markdown (SKILL.md avec frontmatter YAML), bash (`install.sh`).

**Spec:** `docs/superpowers/specs/2026-05-15-reorg-agents-skills-design.md`

**Note de méthode :** ce lot ne produit que des fichiers de config Markdown — pas de code testable. La « vérification » de chaque tâche est une inspection (`grep`, `cat`, `ls`), pas un test unitaire. La vérification de bout en bout (déploiement réel) est la Tâche 8.

---

### Task 1: Créer le skill `stack-python`

**Files:**
- Create: `skills/stack-python/SKILL.md`

- [ ] **Step 1: Écrire le fichier**

Créer `skills/stack-python/SKILL.md` avec exactement ce contenu :

```markdown
---
name: stack-python
description: Conventions Python de Cyril — uv, ruff, mypy strict, pytest, typer+rich. Charger à l'édition de .py, pyproject.toml, ou pour une question Python avancée.
---

# Stack Python

Python 3.12+. Toolchain : `uv` (deps + venv), `ruff` (lint + format), `mypy` (strict), `pytest`.
CLI : `typer` (Click + type hints) + `rich` (tables, progress, output stylisé) par défaut.

## Priorités (dans l'ordre)

1. Type hints complets — pas de `Any` sans justification, mypy strict mode
2. Patterns async corrects — pas d'`asyncio.run()` dans une coroutine
3. Pydantic v2 pour la validation — pas de dicts non typés en API
4. `ruff format` + `ruff check` — zéro warning (formatage auto via hooks, ne pas relancer à la main)

## Commandes

\`\`\`bash
uv add <package>              # jamais pip install directement
uv run ruff check --fix .
uv run ruff format .
uv run mypy .
uv run pytest
\`\`\`

## Règles absolues

- `async def` pour toute fonction qui touche I/O (DB, HTTP, fichiers)
- `HTTPException` avec status codes sémantiques dans FastAPI
- Fixtures pytest pour l'isolation — pas de side effects entre tests
- Exceptions typées hiérarchisées, jamais `raise Exception("message")`
- Pas de catch silencieux

Toujours expliquer les trade-offs async vs sync pour les choix non évidents.
```

- [ ] **Step 2: Vérifier le fichier**

Run: `head -3 skills/stack-python/SKILL.md`
Expected: les 3 premières lignes affichent `---`, `name: stack-python`, `description: ...`

- [ ] **Step 3: Commit**

```bash
git add skills/stack-python/SKILL.md
git commit -m "feat(skills): ajoute stack-python (conventions Python extraites de python-pro)"
```

---

### Task 2: Créer le skill `stack-ts`

**Files:**
- Create: `skills/stack-ts/SKILL.md`

- [ ] **Step 1: Écrire le fichier**

Créer `skills/stack-ts/SKILL.md` avec exactement ce contenu :

```markdown
---
name: stack-ts
description: Conventions TypeScript/JavaScript de Cyril — bun uniquement, jamais npm/node. Charger à l'édition de .ts/.tsx, package.json, ou pour une question TypeScript.
---

# Stack TypeScript

`bun` uniquement — runtime, package manager, bundler, test runner.
**Jamais npm / pnpm / yarn / node.**

## Commandes

\`\`\`bash
bun add <package>
bun install
bun run <script>
bun test
bun build
\`\`\`

## Priorités (dans l'ordre)

1. Types stricts — `strict: true` dans `tsconfig.json`, pas d'`any` implicite
2. Gestion d'erreurs explicite — pas de catch silencieux
3. `prettier` pour le format (auto via hooks, ne pas relancer à la main)

## Règles absolues

- Toute commande passe par `bun` — installation, scripts, tests, build
- Pas de `node_modules` géré par un autre outil que `bun`
- Un module = une responsabilité
```

- [ ] **Step 2: Vérifier le fichier**

Run: `head -3 skills/stack-ts/SKILL.md`
Expected: `---`, `name: stack-ts`, `description: ...`

- [ ] **Step 3: Commit**

```bash
git add skills/stack-ts/SKILL.md
git commit -m "feat(skills): ajoute stack-ts (conventions bun/TypeScript)"
```

---

### Task 3: Créer le skill `stack-rust`

**Files:**
- Create: `skills/stack-rust/SKILL.md`

- [ ] **Step 1: Écrire le fichier**

Créer `skills/stack-rust/SKILL.md` avec exactement ce contenu :

```markdown
---
name: stack-rust
description: Conventions Rust de Cyril — édition 2021, borrow checker, clippy pedantic, thiserror/anyhow. Charger à l'édition de .rs, Cargo.toml, ou pour une question Rust.
---

# Stack Rust

Rust édition 2021.

## Priorités (dans l'ordre)

1. Satisfaction du borrow checker — pas d'`unsafe` sans justification explicite
2. Idiomes Rust : itérateurs, `?` propagation, traits `From`/`Into`, `Display`/`Error`
3. Zero-cost abstractions — pas d'allocations inutiles
4. `clippy::all` + `clippy::pedantic` — zéro warning

## Commandes

\`\`\`bash
cargo clippy --all-targets -- -W clippy::pedantic
cargo fmt
cargo test
\`\`\`

## Règles absolues

- Jamais `unwrap()` / `expect()` hors `#[cfg(test)]`
- `thiserror` pour les erreurs de librairie, `anyhow` pour les binaires
- `derive(Debug, Clone)` par défaut sur les structs publics
- Lifetime elision partout où c'est possible

Toujours expliquer POURQUOI le borrow checker se plaint, pas juste comment le contourner.
```

- [ ] **Step 2: Vérifier le fichier**

Run: `head -3 skills/stack-rust/SKILL.md`
Expected: `---`, `name: stack-rust`, `description: ...`

- [ ] **Step 3: Commit**

```bash
git add skills/stack-rust/SKILL.md
git commit -m "feat(skills): ajoute stack-rust (conventions Rust extraites de rust-pro)"
```

---

### Task 4: Créer le skill `api-design`

**Files:**
- Create: `skills/api-design/SKILL.md`

- [ ] **Step 1: Écrire le fichier**

Créer `skills/api-design/SKILL.md` avec exactement ce contenu :

```markdown
---
name: api-design
description: Conception d'API REST/GraphQL — endpoints, schémas OpenAPI, versioning, pagination, auth. Charger pour designer ou refactorer une API.
---

# API Design

Contexte par défaut : FastAPI (Python) côté backend.

## Priorités (dans l'ordre)

1. Contrat d'abord — schéma OpenAPI / types avant l'implémentation
2. Cohérence — nommage, codes HTTP, format d'erreur uniformes sur toute l'API
3. Évolutivité — versioning explicite, champs optionnels, pas de breaking change silencieux
4. DX — l'API doit être devinable ; un consommateur ne doit pas avoir à lire le code

## Règles absolues

- REST : ressources au pluriel, verbes HTTP sémantiques, jamais de verbe dans l'URL
- Codes statut précis : 201 création, 204 sans corps, 409 conflit, 422 validation
- Erreurs : format unique (`type`, `message`, `details`) — jamais une string nue
- Pagination par curseur pour les collections potentiellement larges, pas d'offset
- Pydantic v2 pour les schémas request/response — modèles distincts de l'ORM
- Auth : OAuth2/JWT via dépendances FastAPI ; scopes explicites par endpoint
- GraphQL uniquement si le besoin de requêtes flexibles le justifie — sinon REST

Toujours exposer un schéma OpenAPI à jour et expliquer les choix de versioning.
```

- [ ] **Step 2: Vérifier le fichier**

Run: `head -3 skills/api-design/SKILL.md`
Expected: `---`, `name: api-design`, `description: ...`

- [ ] **Step 3: Commit**

```bash
git add skills/api-design/SKILL.md
git commit -m "feat(skills): ajoute api-design (compétence extraite de l'agent api-designer)"
```

---

### Task 5: Recâbler `fullstack-developer` et supprimer les 3 agents

**Files:**
- Modify: `agents/fullstack-developer.md`
- Delete: `agents/python-pro.md`, `agents/rust-pro.md`, `agents/api-designer.md`

- [ ] **Step 1: Recâbler `fullstack-developer.md`**

Dans `agents/fullstack-developer.md`, remplacer cette ligne (dans « Règles absolues ») :

```
- `async` de la DB à l'endpoint ; `uv` côté Python, `bun` côté TS — jamais npm/node
```

par :

```
- `async` de la DB à l'endpoint ; conventions outillage dans les skills `stack-python` (couche API) et `stack-ts` (couche UI)
```

- [ ] **Step 2: Recâbler la délégation d'API dans `fullstack-developer.md`**

Toujours dans `agents/fullstack-developer.md`, remplacer le paragraphe final :

```
Pour les choix d'architecture macro, déléguer à `software-architect` ; pour le
design d'API détaillé, à `api-designer`.
```

par :

```
Pour les choix d'architecture macro, déléguer à `software-architect`. Pour le
design d'API détaillé, charger le skill `api-design`.
```

- [ ] **Step 3: Supprimer les 3 agents**

```bash
git rm agents/python-pro.md agents/rust-pro.md agents/api-designer.md
```

- [ ] **Step 4: Vérifier**

Run: `grep -rl 'api-designer\|python-pro\|rust-pro' agents/ ; ls agents/`
Expected: aucune ligne de `grep` (plus aucune référence) ; `ls` affiche uniquement `fullstack-developer.md` et `software-architect.md`

- [ ] **Step 5: Commit**

```bash
git add agents/
git commit -m "refactor(agents): retire python-pro/rust-pro/api-designer, recâble fullstack-developer vers les skills stack"
```

---

### Task 6: Mettre à jour `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (section « Agents custom »)

- [ ] **Step 1: Remplacer la section « Agents custom »**

Dans `CLAUDE.md`, remplacer ce bloc :

```
## Agents custom
Agents spécialisés dans `~/.claude/agents/` (besoins non couverts par les plugins) :
- `software-architect` — choix de stack, ADR, conception macro (Opus)
- `fullstack-developer` — features complètes DB→API→UI
- `api-designer` — design REST/GraphQL, OpenAPI, versioning
- `python-pro` — FastAPI, Pydantic, async, uv, ruff, mypy, pytest
- `rust-pro` — idiomes Rust, borrow checker, clippy
```

par :

```
## Agents custom
**Principe : les skills portent les compétences, les agents définissent les
métiers.** Une spécialisation de langage ou une technique (Python, Rust, design
d'API) est une compétence → skill (`stack-python`, `stack-rust`, `stack-ts`,
`api-design`), pas un agent.

Agents (métiers) spécialisés dans `~/.claude/agents/` :
- `software-architect` — choix de stack, ADR, conception macro (Opus)
- `fullstack-developer` — features complètes DB→API→UI
```

(Les lignes suivantes — « Bibliothèque de référence… » — restent inchangées.)

- [ ] **Step 2: Vérifier**

Run: `grep -n 'python-pro\|rust-pro\|api-designer\|métiers' CLAUDE.md`
Expected: aucune occurrence de `python-pro`/`rust-pro`/`api-designer` ; une occurrence de `métiers`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): énonce le principe skills=compétences/agents=métiers"
```

---

### Task 7: Synchroniser `README.md` et l'audit

**Files:**
- Modify: `README.md` (table des agents, liste des skills custom)
- Modify: `docs/audits/2026-05-15-etat-de-lart-config.md` (plan de marche §7)

- [ ] **Step 1: Mettre à jour la table des agents dans `README.md`**

Remplacer la ligne :

```
| Développement | `fullstack-developer`, `api-designer`, `python-pro`, `rust-pro` |
```

par :

```
| Développement | `fullstack-developer` |
```

- [ ] **Step 2: Ajouter les skills à la liste des skills custom dans `README.md`**

Dans la section « Skills custom », après la ligne `` - `grill-me` — interview contradictoire sur un plan/design ``, ajouter :

```
- `stack-python` — conventions Python (uv, ruff, mypy, pytest)
- `stack-ts` — conventions TypeScript (bun)
- `stack-rust` — conventions Rust (clippy, thiserror/anyhow)
- `api-design` — conception d'API REST/GraphQL
```

- [ ] **Step 3: Mettre à jour le plan de marche de l'audit**

Dans `docs/audits/2026-05-15-etat-de-lart-config.md`, section §7, remplacer la ligne :

```
| **B** | Plugin bootstrap custom | S/M | Brainstorm dédié → spec → plan |
```

par :

```
| **B** | Réorg agents/skills — volet plugin bootstrap abandonné après challenge | S | ✅ Fait |
```

- [ ] **Step 4: Vérifier**

Run: `grep -n 'python-pro\|api-designer' README.md ; grep -n 'Réorg agents/skills' docs/audits/2026-05-15-etat-de-lart-config.md`
Expected: aucune occurrence de `python-pro`/`api-designer` dans `README.md` ; une ligne pour la réorg dans l'audit

- [ ] **Step 5: Commit**

```bash
git add README.md docs/audits/2026-05-15-etat-de-lart-config.md
git commit -m "docs: synchronise README et audit avec la réorg agents/skills"
```

---

### Task 8: Déployer et vérifier de bout en bout

**Files:** aucun (exécution de `install.sh`)

- [ ] **Step 1: Déployer**

Run: `bash install.sh`
Expected: sortie listant `~/.claude/skills/stack-python`, `stack-ts`, `stack-rust`, `api-design` parmi les `✓` ; pas d'erreur.

- [ ] **Step 2: Vérifier les skills déployés**

Run: `ls -l ~/.claude/skills/ | grep -E 'stack-|api-design'`
Expected: 4 symlinks — `stack-python`, `stack-ts`, `stack-rust`, `api-design` — pointant vers `~/src/claude-config/skills/`

- [ ] **Step 3: Vérifier la purge des agents**

Run: `ls ~/.claude/agents/`
Expected: uniquement `fullstack-developer.md` et `software-architect.md` — plus de `python-pro`, `rust-pro`, `api-designer` (purgés par `prune_managed_links`)

- [ ] **Step 4: Vérifier l'intégrité des références**

Run: `grep -rl 'api-designer\|python-pro\|rust-pro' agents/ CLAUDE.md README.md`
Expected: aucune sortie (aucun fichier ne référence plus les agents supprimés)

---

## Notes d'exécution

- Pas de worktree nécessaire — modifications de config localisées, branche `main`.
- Le formatage est géré par les hooks (`format-on-save`) — ne pas relancer manuellement.
- Après la Tâche 8, redémarrer Claude Code pour que les 4 nouveaux skills
  apparaissent dans la liste des skills disponibles d'une session.
