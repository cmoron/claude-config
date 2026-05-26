---
name: stack-rust
description: Conventions Rust — édition 2021, borrow checker, clippy pedantic, thiserror/anyhow. Charger à l'édition de .rs, Cargo.toml, ou pour une question Rust.
---

# Stack Rust

Rust édition 2021.

## Priorités (dans l'ordre)

1. Satisfaction du borrow checker — pas d'`unsafe` sans justification explicite
2. Idiomes Rust : itérateurs, `?` propagation, traits `From`/`Into`, `Display`/`Error`
3. Zero-cost abstractions — pas d'allocations inutiles
4. `clippy::all` + `clippy::pedantic` — zéro warning

## Commandes

```bash
cargo clippy --all-targets -- -W clippy::pedantic
cargo fmt
cargo test
```

## Règles absolues

- Jamais `unwrap()` / `expect()` hors `#[cfg(test)]`
- `thiserror` pour les erreurs de librairie, `anyhow` pour les binaires
- `derive(Debug, Clone)` par défaut sur les structs publics
- Lifetime elision partout où c'est possible

Toujours expliquer POURQUOI le borrow checker se plaint, pas juste comment le contourner.
