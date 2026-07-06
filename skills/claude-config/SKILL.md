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
├── RTK.md                 # Doc RTK (Rust Token Killer), importée par CLAUDE.md
├── settings.json          # Hooks, permissions, MCPs locaux
├── commands/              # Slash commands (/commit, /review, etc.)
├── skills/                # Skills auto-chargés (dossier par skill avec SKILL.md)
├── config/                # Config d'outils tiers déployée (ex: ccstatusline)
├── docs/                  # Audits datés + specs/plans superpowers
├── assets/                # Assets statiques (son de notification)
├── scripts/               # Hooks shell (format-on-save, notify-sound, protect-env) + bootstrap-plugins
├── install.sh             # Déploie via symlinks — idempotent, relancer sans risque
├── update.sh              # Pull + re-installe
└── upstream/              # Submodule : skills officiels Anthropic (anthropic-skills)
```

Pas de dossier `agents/` actuellement (0 agent custom — cf. README § Agents). `snippets/`
n'existe pas non plus.

## MCPs actifs

Trois origines distinctes, à ne pas confondre :

| Origine | Où c'est déclaré | Exemples |
|---|---|---|
| MCP `settings.json` (`mcpServers`) | Ce repo | `linear` (HTTP, `https://mcp.linear.app/sse`) — le seul MCP settings.json |
| Plugin (fournit des tools, pas un MCP) | `settings.json` (`enabledPlugins`) | `context7`, `playwright` |
| Connecteur claude.ai | Compte claude.ai, hors repo | Gmail, Google Calendar, Google Drive, Linear, Coros |

Le connecteur claude.ai Linear fait doublon avec le MCP `linear` de `settings.json` — ce
dernier est la référence (cf. skill `linear`).

`blender` (MCP local) est déclaré dans `~/.claude.json`, hors repo — expérimentation
assumée, pas de gouvernance ici.

## Ajouter un agent

`agents/` n'existe pas actuellement (0 agent custom, cf. README). Au besoin : créer
`agents/<name>.md` avec frontmatter YAML :
```markdown
---
name: mon-agent
description: Ce que fait l'agent — utilisé pour le routing
model: sonnet  # ou opus, haiku
---
# Instructions...
```
Puis `bash install.sh` pour symlinker dans `~/.claude/agents/` — `install.sh` gère déjà
ce dossier même s'il est absent aujourd'hui.

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

## Checklist anti-dérive — OBLIGATOIRE avant de committer une modif de config

La doc de ce repo a dérivé à 3 audits consécutifs (05, 06, 07/2026). Tout
changement de config embarque sa doc **dans le même commit** :

- [ ] Ajout/retrait d'un **skill** → liste des skills dans `README.md` § « Skills custom »
- [ ] Ajout/retrait d'un **plugin** (`enabledPlugins`) → table plugins du `README.md`
- [ ] Ajout/retrait d'un **hook** → table hooks du `README.md`
- [ ] Changement de **structure** (dossier créé/supprimé) → § Structure du `README.md` **et** de ce SKILL.md
- [ ] Ajout/retrait d'un **MCP** → table MCPs de ce SKILL.md

Revue à l'œil, dossier par dossier — pas de script.
