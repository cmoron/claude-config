---
name: rust-dev
description: Activez pour tout code Rust : fichiers .rs, Cargo.toml, AoC, CLI tools, systèmes. Patterns idiomatiques Rust 2021, clippy strict, error handling moderne.
---
# Rust Development — Édition 2021

## Conventions obligatoires
- `#![warn(clippy::all, clippy::pedantic)]` en tête de `lib.rs`
- `thiserror` pour les erreurs de librairie, `anyhow` pour les binaires
- Jamais `unwrap()`/`expect()` hors `#[cfg(test)]` — utiliser `?` ou gérer explicitement
- `derive(Debug, Clone)` par défaut sur les structs publics

## Patterns préférés
```rust
// Itérateurs > boucles for
let total: u32 = items.iter().map(|x| x.value).sum();

// ? propagation systématique
fn parse(s: &str) -> Result<Config, AppError> {
    let n: u32 = s.trim().parse()?;
    Ok(Config { value: n })
}

// From/Into pour les conversions
impl From<IoError> for AppError {
    fn from(e: IoError) -> Self { AppError::Io(e) }
}
```

## Error handling (thiserror)
```rust
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Parse error: {0}")]
    Parse(#[from] std::num::ParseIntError),
    #[error("Invalid input: {0}")]
    Invalid(String),
}
```

## AoC spécifique
- Parser avec split/lines/chars pour les inputs simples, `nom`/`winnow` pour les grammaires
- `BTreeMap` si l'ordre est nécessaire, `HashMap` sinon
- `rayon::par_iter()` pour paralléliser sans friction si part 2 est lent
- Tester avec l'exemple avant le vrai input

## Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;

    const EXAMPLE: &str = "exemple de l'énoncé";

    #[test]
    fn test_part1_example() {
        assert_eq!(part1(EXAMPLE), 42);
    }
}
```
