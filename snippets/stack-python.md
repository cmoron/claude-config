## Stack Python
- Python 3.12, uv, ruff, mypy, pytest
- FastAPI + Pydantic pour les APIs, PostgreSQL

## Commandes
```bash
uv run ruff check . && uv run ruff format --check . && uv run mypy . && uv run pytest
uv add <pkg> / uv run <cmd>
```

## Conventions
- Formatage automatique via hooks ruff — ne pas relancer manuellement
- Gestion d'erreurs explicite — pas de catch silencieux
- Types stricts mypy, pas d'`Any` sauf justification
