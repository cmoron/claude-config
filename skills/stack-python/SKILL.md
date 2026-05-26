---
name: stack-python
description: Conventions Python — uv, ruff, mypy strict, pytest, typer+rich. Charger à l'édition de .py, pyproject.toml, ou pour une question Python avancée.
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

```bash
uv add <package>              # jamais pip install directement
uv run ruff check --fix .
uv run ruff format .
uv run mypy .
uv run pytest
```

## Règles absolues

- `async def` pour toute fonction qui touche I/O (DB, HTTP, fichiers)
- `HTTPException` avec status codes sémantiques dans FastAPI
- Fixtures pytest pour l'isolation — pas de side effects entre tests
- Exceptions typées hiérarchisées, jamais `raise Exception("message")`
- Pas de catch silencieux

Toujours expliquer les trade-offs async vs sync pour les choix non évidents.
