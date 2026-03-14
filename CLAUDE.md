# Claude Code — Cyril Moron

## Principes
- Livraison itérative en tranches verticales (DB → API → UI)
- Comprendre avant de coder : explorer 2-3 fichiers similaires d'abord
- Tests avant ou avec le code — jamais après
- Commit message : explique le POURQUOI, pas le quoi
- Git propre avant de commencer, checkpoints réguliers

## Code quality
- Formatage automatique via hooks (black/ruff/rustfmt/prettier) — ne pas relancer manuellement
- Gestion d'erreurs explicite — pas de catch silencieux, pas de unwrap hors tests
- Un module = une responsabilité

## Stack par projet
- **mypacer / running** : Python 3.12 (FastAPI), Next.js 15 App Router, PostgreSQL
- **AoC / systèmes** : Rust édition 2021, clippy strict
- **configs perso** : Neovim Lua, dotfiles, shell POSIX
- **tooling** : pnpm, black, ruff, prettier, rustfmt

## Commandes de référence
```
# Python
black . && ruff check . && pytest

# Rust
cargo clippy --all-targets -- -D warnings && cargo test && cargo fmt

# Next.js
pnpm build && pnpm test
```

## Gestion du contexte (important pour plan Pro)
- /clear entre deux tâches distinctes — toujours
- /compact manuel avant d'atteindre 50% de contexte
- Ne jamais @-mentionner un gros fichier : indiquer le chemin + pourquoi le lire
- Préférer des questions ciblées à des "explore tout le projet"
