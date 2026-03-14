---
name: running-app
description: Activez pour mypacer, running_pace_api, bases_athle_scrapper, mypacer_scraper, mypacer_web. Domaine métier running/athlétisme : paces, formats FFA, scraping bases_athle.
---
# Domaine métier : Running / Athlétisme

## Formats et types
- **Pace** : stocker en `int` (secondes/km), afficher en `MM:SS/km`
- **Distance** : en mètres `int` (jamais float — évite les arrondis)
- **Temps** : en secondes `int` pour les calculs, converti à l'affichage
- **Date compétition** : ISO 8601 `YYYY-MM-DD`

## Conversions de référence
```python
def pace_s_per_km(distance_m: int, time_s: int) -> int:
    """Pace en secondes/km."""
    return round((time_s / distance_m) * 1000)

def format_pace(seconds_per_km: int) -> str:
    """Affichage MM:SS/km."""
    return f"{seconds_per_km // 60}:{seconds_per_km % 60:02d}/km"

def format_time(total_seconds: int) -> str:
    """Affichage H:MM:SS ou MM:SS selon la durée."""
    h, rem = divmod(total_seconds, 3600)
    m, s = divmod(rem, 60)
    if h > 0:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"
```

## Scraping bases_athle
- Rate limit : 1 req/s minimum — toujours
- User-Agent : simuler un navigateur réel
- Format de sortie : `{"athlete_id": str, "name": str, "results": [Result]}`
- `Result` : `{"date": str, "competition": str, "distance_m": int, "time_s": int, "place": int | None}`

## APIs mypacer
- Base URL : variable d'env `MYPACER_API_URL`
- Auth : JWT Bearer, rotation via refresh token
- Pagination : `?page=1&per_page=50` (max 100)
- Rate limit : 100 req/min par token

## Catégories FFA
- Benjamin (12-13 ans), Minime (14-15), Cadet (16-17), Junior (18-19)
- Espoir (20-22), Senior (23-39), Master M0 (40-49), M1 (50-59), M2 (60-69), M3 (70+)
- Distinguer H (hommes) et F (femmes) dans toutes les catégories
