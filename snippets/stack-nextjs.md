## Stack Next.js
- Next.js 15 App Router, TypeScript, bun, prettier

## Commandes
```bash
bun run build && bun test
bun run lint && bun run type-check
```

## Conventions
- Formatage automatique via hooks prettier — ne pas relancer manuellement
- App Router uniquement — pas de `pages/`
- Server Components par défaut, `"use client"` seulement si nécessaire
