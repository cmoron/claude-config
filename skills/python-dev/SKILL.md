---
name: python-dev
description: Activez pour Python : FastAPI, Django, scripts, scraping, data processing. Type hints, black, ruff, pytest. Projets mypacer_api, mypacer_scraper, bases_athle_scrapper.
---
# Python Development — 3.12+

## Conventions obligatoires
- Type hints partout : `def f(x: int) -> str:`
- `black` pour formatting (line-length=88, défaut)
- `ruff` pour linting : règles E, F, I, UP, B activées
- `pytest` avec fixtures — jamais `unittest` directement

## FastAPI patterns
```python
from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel

class ItemCreate(BaseModel):
    name: str
    value: float

@app.post("/items", status_code=status.HTTP_201_CREATED)
async def create_item(
    item: ItemCreate,
    db: AsyncSession = Depends(get_db),
) -> Item:
    ...
```

## Error handling
```python
# Exceptions typées, jamais de raise Exception("message")
class AppError(Exception):
    def __init__(self, message: str, code: int = 400) -> None:
        self.message = message
        self.code = code
        super().__init__(message)

class NotFoundError(AppError):
    def __init__(self, resource: str) -> None:
        super().__init__(f"{resource} non trouvé", code=404)
```

## Tests pytest
```python
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client(app, db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    async with AsyncClient(app=app, base_url="http://test") as c:
        yield c

async def test_create_item(client):
    response = await client.post("/items", json={"name": "test", "value": 1.0})
    assert response.status_code == 201
```

## Scraping (BeautifulSoup)
```python
import asyncio
import httpx
from bs4 import BeautifulSoup

# Toujours respecter un rate limit
async def fetch_page(url: str, delay: float = 1.0) -> BeautifulSoup:
    await asyncio.sleep(delay)
    response = httpx.get(url, timeout=10.0)
    response.raise_for_status()
    return BeautifulSoup(response.text, "html.parser")
```
