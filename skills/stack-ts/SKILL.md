---
name: stack-ts
description: Conventions TypeScript/JavaScript — bun uniquement, jamais npm/node. Charger à l'édition de .ts/.tsx, package.json, ou pour une question TypeScript.
---

# Stack TypeScript

`bun` uniquement — runtime, package manager, bundler, test runner.
**Jamais npm / pnpm / yarn / node.**

## Commandes

```bash
bun add <package>
bun install
bun run <script>
bun test
bun build
```

## Priorités (dans l'ordre)

1. Types stricts — `strict: true` dans `tsconfig.json`, pas d'`any` implicite
2. Gestion d'erreurs explicite — pas de catch silencieux
3. `prettier` pour le format (auto via hooks, ne pas relancer à la main)

## Règles absolues

- Toute commande passe par `bun` — installation, scripts, tests, build
- Pas de `node_modules` géré par un autre outil que `bun`
- Un module = une responsabilité
