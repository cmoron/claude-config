---
name: claude-config
description: Pour modifier la configuration Claude Code : agents, skills, commands, settings, CLAUDE.md.
---

# Claude Code Config — ~/src/claude-config

Ce repo centralise toute la configuration Claude Code personnelle. Il est symlinké vers `~/.claude/` via `install.sh`.

## Structure

```
~/src/claude-config/
├── CLAUDE.md              # Instructions globales (toujours chargé)
├── settings.json          # Hooks, permissions, MCPs locaux
├── agents/                # Sous-agents spécialisés (.md par agent)
├── commands/              # Slash commands (/commit, /review, etc.)
├── skills/                # Skills auto-chargés (dossier par skill avec SKILL.md)
├── snippets/              # Blocs injectés dynamiquement (ex: stack spécifique)
├── scripts/               # Hooks shell (format-on-save, notify-sound, protect-env) + bootstrap-plugins
├── install.sh             # Déploie via symlinks — idempotent, relancer sans risque
├── update.sh              # Pull + re-installe
└── upstream/              # Submodule : skills officiels Anthropic (anthropic-skills)
```

## MCPs actifs

Configurés dans `settings.json` ou via `claude mcp add` :

| MCP | Type | Usage |
|-----|------|-------|
| `claude.ai Linear` | Remote (Anthropic) | Gestion projets Linear |
| `claude.ai Gmail` | Remote (Anthropic) | Lecture/envoi emails |
| `claude.ai Google Calendar` | Remote (Anthropic) | Agenda |
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
Puis `bash install.sh` pour symlinker dans `~/.claude/agents/`.

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

## Écrire un hook — pièges vérifiés

- **Stop hook : ne JAMAIS bloquer via `exit 2`** → s'affiche « Stop hook error ».
  Pour forcer un tour proprement : `exit 0` + JSON stdout `{"decision":"block","reason":"…"}`.
- **Pas de texte non-ASCII multi-ligne via `python … "$ARG"`** en headless : argv
  décodé sous locale non-UTF-8 → mojibake + JSON cassé. Hand-write le JSON
  (`printf '%s'`, `\n` échappés) si le texte n'a ni `"` ni `\`.
- **Tester la sortie d'un hook : `printf`, jamais `echo`** — la Bash tool tourne
  sous zsh, qui interprète les `\n` de `echo` et corrompt le JSON avant `jq`.
- **Robustesse** : parse stdin en try/except (cf. `protect-env.sh`), dégrade en
  `exit 0` (no-op) à la moindre incertitude — ne bloque jamais à tort.

## Conventions

- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)
- Ne pas modifier directement dans `~/.claude/` — tout passe par le repo
- Les snippets dans `snippets/` sont des blocs markdown injectés manuellement ou via hooks
