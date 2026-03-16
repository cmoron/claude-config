# Claude Code — Cyril Moron

## Principes
- Livraison itérative en tranches verticales (DB → API → UI)
- Comprendre avant de coder : explorer 2-3 fichiers similaires d'abord
- Tests avant ou avec le code — jamais après
- Git linéaire uniquement : rebase, pas de merge commits
- Conventional Commits — message = POURQUOI, pas le quoi

## Code quality
- Formatage automatique via hooks (ruff/rustfmt/prettier) — ne pas relancer manuellement
- Gestion d'erreurs explicite — pas de catch silencieux, pas de unwrap hors tests
- Un module = une responsabilité

## Toolchains
- Python : `uv` (gestion deps/envs), `ruff` (lint + format), `mypy` (types), `pytest`
- JavaScript/TypeScript : `bun` uniquement (runtime, package manager, bundler, test runner) — pas de npm/pnpm/yarn/node

## Workflow
- Entrer en plan mode pour toute tâche 3+ étapes ou décision architecturale
- Sur un bug : diagnostiquer et corriger sans demander confirmation — pointer les logs, corriger
- Ne jamais déclarer une tâche terminée sans avoir prouvé qu'elle fonctionne
- Pause sur les changements non-triviaux : "existe-t-il une solution plus élégante ?"

## Auto-amélioration
- Après toute correction : mettre à jour `tasks/lessons.md` avec la règle (date | contexte | règle)
- Relire `tasks/lessons.md` en début de session si présent

## Agents disponibles
Agents actifs dans `~/.claude/agents/` :

**Conception & architecture**
- `software-architect` — choix de stack, ADR, conception macro, trade-offs (Opus)
- `architect-reviewer` — cohérence archi, patterns, API contracts sur code existant

**Développement**
- `fullstack-developer` — features complètes DB→API→UI
- `api-designer` — design REST/GraphQL, OpenAPI, versioning
- `ui-designer` — design system, composants, accessibilité
- `python-pro` — FastAPI, Pydantic, async, uv, ruff, mypy, pytest
- `rust-pro` — idiomes Rust, borrow checker, clippy, AoC

**Qualité & sécurité**
- `code-reviewer` — revue diff : sécurité → correction → perf → lisibilité
- `debugger` — root cause + fix minimal + vérification
- `security-auditor` — OWASP, secrets, vulns, revue sécurité
- `penetration-tester` — tests d'intrusion, exploitation, rapport
- `compliance-auditor` — conformité GDPR, SOC2, ISO 27001

**Infrastructure & ops**
- `devops` — serveurs, infra, CI/CD, configs système (custom)
- `docker-expert` — images Docker, multi-stage builds, sécurité conteneurs
- `deployment-engineer` — pipelines CI/CD, stratégies de déploiement
- `sre-engineer` — SLO/SLI, observabilité, fiabilité, incident response
- `it-ops-orchestrator` — coordination multi-agents pour tâches ops complexes

Bibliothèque de référence (141 agents) : `~/src/claude-config/upstream/awesome-claude-code-subagents/`
→ Si un besoin émerge, copier l'agent pertinent dans `agents/` et l'adapter.

## Commandes slash
- `/bootstrap` — génère un CLAUDE.md pour le projet courant
- `/implement <feature>` — implémente avec tests (explore → plan → TDD → commit)
- `/review` — revue du diff courant, priorisé par sévérité
- `/commit` — génère un commit message sémantique (Conventional Commits)

## Gestion du contexte (plan Pro)
- `/clear` entre deux tâches distinctes — toujours
- `/compact` manuel avant d'atteindre 50% de contexte
- Ne jamais @-mentionner un gros fichier : indiquer le chemin + pourquoi le lire
- Préférer des questions ciblées à des "explore tout le projet"
