## Stack Rust
- Rust édition 2021, clippy strict, rustfmt

## Commandes
```bash
cargo clippy --all-targets -- -D warnings && cargo test && cargo fmt
```

## Conventions
- Formatage automatique via hooks rustfmt — ne pas relancer manuellement
- Pas d'`unwrap` hors tests — gestion d'erreurs explicite (`?`, `thiserror`)
- Clippy warnings = erreurs
