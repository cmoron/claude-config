# Claude Code — Cyril Moron

## Principes
- Livraison itérative en tranches verticales (DB → API → UI)
- Comprendre avant de coder : explorer 2-3 fichiers similaires d'abord
- Tests avant ou avec le code — jamais après
- Git linéaire uniquement : rebase, pas de merge commits
- Conventional commits — message = POURQUOI, pas le quoi

## Code quality
- Formatage automatique via hooks (ruff/rustfmt/prettier) — ne pas relancer manuellement
- Gestion d'erreurs explicite — pas de catch silencieux, pas de unwrap hors tests
- Un module = une responsabilité

## Stack par projet
- **mypacer / running** : Python 3.12 (FastAPI, uv, ruff, mypy), Next.js 15 App Router, PostgreSQL
- **AoC / systèmes** : Rust édition 2021, clippy strict
- **configs perso** : Neovim Lua, dotfiles, shell POSIX
- **tooling** : pnpm, ruff, mypy, prettier, rustfmt, uv

## Commandes de référence
```bash
# Python (uv)
uv run ruff check . && uv run ruff format --check . && uv run mypy . && uv run pytest

# Rust
cargo clippy --all-targets -- -D warnings && cargo test && cargo fmt

# Next.js
pnpm build && pnpm test
```

## Agents disponibles
Agents actifs dans `~/.claude/agents/` :
- `code-reviewer` — revue diff : sécurité → correction → perf → lisibilité
- `debugger` — root cause + fix minimal + vérification
- `rust-pro` — idiomes Rust, borrow checker, clippy, AoC
- `python-pro` — FastAPI, Pydantic, async, uv, ruff, mypy, pytest
- `security-auditor` — OWASP, secrets, vulns, revue sécurité
- `architect-reviewer` — cohérence archi, patterns, API contracts
- `devops` — serveurs, infra, configs système, agents IA

Bibliothèque de référence (127+ agents) : `~/src/claude-config/upstream/awesome-claude-code-subagents/`
→ Si un besoin émerge, copier l'agent pertinent dans `~/.claude/agents/` et l'adapter.

## Commandes slash
- `/bootstrap` — génère un CLAUDE.md pour le projet courant
- `/implement <feature>` — implémente avec tests (explore → plan → TDD → commit)
- `/review` — revue du diff courant, priorisé par sévérité
- `/commit` — génère un commit message sémantique (Conventional Commits)

## Gestion du contexte (plan Pro)
- `/clear` entre deux tâches distinctes — toujours
- `/compact` manuel avant d'atteindre 50% de contexte
- Ne jamais @-mentionner un gros fichier : indiquer le chemin + pourquoi le lire
- Préférer des questions ciblées à des "explore tout le projet"
