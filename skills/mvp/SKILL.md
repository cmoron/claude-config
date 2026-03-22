---
name: mvp
description: Pour créer un MVP ou POC rapidement avec les stacks préférées. Évite les choix par défaut inadaptés (pas de Next.js, pas de npm/yarn/node).
---

# MVP / POC — Stacks et conventions

Utiliser ce skill dès qu'on démarre un nouveau projet de zéro : MVP, POC, prototype, side project.

## Choix de stack selon le besoin

### API seule / Backend pur
**FastAPI + Python**
```
monprojet/
├── pyproject.toml         # uv, dépendances
├── src/monprojet/
│   ├── main.py            # FastAPI app
│   ├── models.py          # SQLAlchemy models
│   ├── schemas.py         # Pydantic schemas
│   ├── database.py        # Session Postgres
│   └── routers/
├── tests/
├── Dockerfile
├── docker-compose.yml
└── .github/workflows/ci.yml
```
- ORM : SQLAlchemy async + Alembic migrations
- Auth : JWT (python-jose) ou pas d'auth si POC
- **Jamais** de `pip install` — toujours `uv add`

### Web app complète (UI non critique)
**FastAPI + Svelte + Vite**
```
monprojet/
├── backend/               # FastAPI (cf. ci-dessus)
├── frontend/              # Svelte + Vite, géré par Bun
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
├── docker-compose.yml     # backend + frontend + postgres
└── .github/workflows/
```
- Bundler/runtime JS : **Bun uniquement** (`bun install`, `bun run dev`)
- Svelte (pas SvelteKit sauf si routing SSR vraiment nécessaire)
- Vite pour le dev server
- Pas de Next.js

### Monorepo full-JS (si équipe JS ou client React imposé)
**React + Express + Bun**
```
monprojet/
├── apps/
│   ├── api/               # Express (TypeScript, Bun)
│   └── web/               # React + Vite (Bun)
├── packages/
│   └── shared/            # Types partagés
├── package.json           # workspace Bun
├── docker-compose.yml
└── .github/workflows/
```
- ORM : Prisma (TypeScript-first, fonctionne avec Express)
- Runtime : Bun partout — **pas de npm, pnpm, yarn, node**
- Biome pour lint + format (remplace ESLint + Prettier)

### CLI seule
**Python + Typer**
```
monprojet/
├── pyproject.toml
├── src/monprojet/
│   ├── cli.py             # Typer app
│   └── core.py
├── tests/
└── Dockerfile
```
- Sortie : JSON sur stdout, erreurs sur stderr, exit 0/1
- Toujours : `--help` exploitable par un agent

## Base de données

- **Toujours Postgres** (pas de SQLite sauf contrainte explicite)
- Lancer via docker-compose en dev :
```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_DB: monprojet
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
  ports:
    - "5432:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
```
- Migrations : Alembic (FastAPI) ou Prisma migrate (Express)

## Docker / Docker Compose

Chaque projet doit avoir un `docker-compose.yml` fonctionnel dès le départ :
- `app` (ou `backend` + `frontend`)
- `postgres`
- Variables d'env dans `.env` (jamais hardcodées)
- Multi-stage Dockerfile pour les images de prod

## CI/CD — GitHub Actions minimal

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup (Python ou Bun selon stack)
      - name: Lint
      - name: Tests
```

## Versioning

- Git + GitHub, trunk-based (branche `main` unique pour les POC)
- Conventional commits : `feat:`, `fix:`, `chore:`, `docs:`
- `.gitignore` adapté dès le départ (`.env`, `__pycache__`, `node_modules`, etc.)

## Lint par langage

| Langage | Lint | Format |
|---------|------|--------|
| Python | `ruff check` | `ruff format` |
| TypeScript/JS | Biome (`biome check`) | Biome |
| Svelte | Biome + svelte-check | Biome |

## Ce qu'on n'utilise pas

- Next.js (trop opinionated, SSR souvent inutile pour un POC)
- npm, yarn, pnpm (Bun uniquement côté JS)
- SQLite en prod
- `unittest` Python (pytest uniquement)
- `pip install` directement (uv uniquement)
