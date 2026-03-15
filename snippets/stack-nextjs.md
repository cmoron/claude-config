## Stack Next.js
- Next.js 15 App Router, TypeScript, pnpm, prettier

## Commandes
```bash
pnpm build && pnpm test
pnpm lint && pnpm type-check
```

## Conventions
- Formatage automatique via hooks prettier — ne pas relancer manuellement
- App Router uniquement — pas de `pages/`
- Server Components par défaut, `"use client"` seulement si nécessaire
