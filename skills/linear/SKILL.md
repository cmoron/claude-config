---
name: linear
description: Pour gérer les projets Linear de l'usine à SaaS avec Estelle. Cyril Dev/CTO, Estelle PM/PO. Sprints scrum 1 semaine, backlog libre actuellement.
---

# Linear — Usine à SaaS (Cyril + Estelle)

Linear est utilisé pour gérer les projets de l'usine à SaaS.
Le **MCP remote Linear** est actif — il gère les appels API. Ce skill documente les conventions d'usage.

## Équipe

| Personne | Rôle |
|----------|------|
| Cyril | Dev / CTO — implémentation, architecture, code review |
| Estelle | PM / PO / Marketing — specs, priorités, feedback utilisateur |

## Organisation

- **Un seul workspace** Linear, plusieurs projets (un par produit SaaS)
- Pas de labels ou statuts custom pour l'instant — statuts Linear par défaut
- Sprints scrum d'**une semaine**, mais gestion actuelle principalement en **backlog libre**

## Statuts par défaut utilisés

- `Backlog` → idées non priorisées
- `Todo` → priorisé pour le sprint en cours
- `In Progress` → en cours de développement (Cyril)
- `In Review` → PR ouverte, en attente de review
- `Done` → terminé et mergé
- `Cancelled` → abandonné

## Conventions issues

- **Titre** : court et actionnable (`Ajouter l'auth Google`, pas `Feature auth`)
- **Description** : contexte + critères d'acceptance (Estelle rédige, Cyril complète si besoin)
- **Assigné** : toujours assigné à quelqu'un dès qu'il passe en `Todo`
- Lier les issues aux PRs GitHub quand possible

## Workflow avec le MCP

Le MCP Linear permet à Claude de :
- Lister les issues d'un projet (`list_issues`)
- Créer une issue (`save_issue`)
- Mettre à jour le statut (`save_issue` avec nouveau status)
- Consulter un projet ou une équipe

Exemple de flux typique :
```
1. Lister les issues en backlog pour prioriser le sprint
2. Créer les issues manquantes issues de la conversation
3. Passer les issues du sprint en Todo
4. En fin de sprint, passer Done les issues terminées
```

## Priorités

Utiliser les priorités Linear standard :
- `Urgent` → bloquant, traiter aujourd'hui
- `High` → sprint en cours
- `Medium` → prochain sprint
- `Low` → backlog diffus

## Ce qu'on ne fait pas (encore)

- Pas de cycles/sprints configurés dans Linear (gestion manuelle pour l'instant)
- Pas de labels custom
- Pas d'automatisations Linear actives
