---
name: claude-config
description: Pour modifier la configuration Claude Code de Cyril : agents, skills, commands, settings, CLAUDE.md. Repo ~/src/claude-config symlinkévers ~/.claude.
---

# Claude Code Config — ~/src/claude-config

Ce repo centralise toute la configuration Claude Code personnelle. Il est symlinkévers `~/.claude/` via `install.sh`.

## Structure

```
~/src/claude-config/
├── CLAUDE.md              # Instructions globales (toujours chargé)
├── settings.json          # Hooks, permissions, MCPs locaux
├── agents/                # Sous-agents spécialisés (.md par agent)
├── commands/              # Slash commands (/commit, /review, etc.)
├── skills/                # Skills auto-chargés (dossier par skill avec SKILL.md)
├── snippets/              # Blocs injectés dynamiquement (ex: stack spécifique)
├── scripts/               # Scripts utilitaires (bell.sh, etc.)
├── install.sh             # Déploie via symlinks — idempotent, relancer sans risque
├── update.sh              # Pull + re-installe
└── upstream/              # Bibliothèque de référence (agents tiers, etc.)
```

## MCPs actifs

Configurés dans `settings.json` ou via `claude mcp add` :

| MCP | Type | Usage |
|-----|------|-------|
| `claude.ai Linear` | Remote (Anthropic) | Gestion projets Linear |
| `claude.ai Gmail` | Remote (Anthropic) | Lecture/envoi emails |
| `claude.ai Google Calendar` | Remote (Anthropic) | Agenda |
| `claude-mem` | Plugin (thedotmack) | Mémoire cross-sessions |
| `context7` | Local (`npx`) | Docs libraries à jour |
| `playwright` | Local (`npx`) | Browser automation |

Les remote MCPs (Linear, Gmail, Calendar) ne consomment pas de ressources locales — auth gérée par Anthropic.

## Ajouter un agent

Créer `agents/<name>.md` avec frontmatter YAML :
```markdown
---
name: mon-agent
description: Ce que fait l'agent — utilisé pour le routing
model: sonnet  # ou opus, haiku
---
# Instructions...
```
Puis `bash install.sh` pour symlinkerdans `~/.claude/agents/`.

## Ajouter un skill

Créer `skills/<name>/SKILL.md` :
```markdown
---
name: mon-skill
description: 1-3 lignes — injectées dans le contexte à chaque session pour décider si pertinent
---
# Instructions complètes chargées à la demande...
```
Puis `bash install.sh`.

## Ajouter une commande slash

Créer `commands/<name>.md` — sera disponible comme `/<name>` dans Claude Code.

## Déployer les changements

```bash
cd ~/src/claude-config
bash install.sh    # symlinks uniquement, idempotent
# Ou pour pull + install :
bash update.sh
```

## Conventions

- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- Ne pas modifier directement dans `~/.claude/` — tout passe par le repo
- Les snippets dans `snippets/` sont des blocs markdown injectés manuellement ou via hooks
