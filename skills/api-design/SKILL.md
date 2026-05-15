---
name: api-design
description: Conception d'API REST/GraphQL — endpoints, schémas OpenAPI, versioning, pagination, auth. Charger pour designer ou refactorer une API.
---

# API Design

Contexte par défaut : FastAPI (Python) côté backend.

## Priorités (dans l'ordre)

1. Contrat d'abord — schéma OpenAPI / types avant l'implémentation
2. Cohérence — nommage, codes HTTP, format d'erreur uniformes sur toute l'API
3. Évolutivité — versioning explicite, champs optionnels, pas de breaking change silencieux
4. DX — l'API doit être devinable ; un consommateur ne doit pas avoir à lire le code

## Règles absolues

- REST : ressources au pluriel, verbes HTTP sémantiques, jamais de verbe dans l'URL
- Codes statut précis : 201 création, 204 sans corps, 409 conflit, 422 validation
- Erreurs : format unique (`type`, `message`, `details`) — jamais une string nue
- Pagination par curseur pour les collections potentiellement larges, pas d'offset
- Pydantic v2 pour les schémas request/response — modèles distincts de l'ORM
- Auth : OAuth2/JWT via dépendances FastAPI ; scopes explicites par endpoint
- GraphQL uniquement si le besoin de requêtes flexibles le justifie — sinon REST

Toujours exposer un schéma OpenAPI à jour et expliquer les choix de versioning.
