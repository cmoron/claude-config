# claude-config

Configuration personnelle Claude Code, versionnée sous git.

## Structure

```
.
├── CLAUDE.md           # Instructions globales (slim ~70 lignes)
├── settings.json       # Permissions + hooks (format, protection .env, bell)
├── install.sh          # Déploie les symlinks dans ~/.claude/
├── update.sh           # Met à jour les submodules upstream + redéploie
├── scripts/
│   ├── format-on-save.sh   # PostToolUse : black/rustfmt/prettier automatique
│   ├── protect-env.sh      # PreToolUse : bloque les écritures .env
│   └── bell.sh             # Stop/Notification : bell terminal
├── agents/
│   ├── code-reviewer.md    # haiku — revue de code rapide
│   ├── rust-pro.md         # sonnet — expert Rust
│   └── debugger.md         # haiku — debugging systématique
├── commands/
│   ├── implement.md        # /implement <feature>
│   ├── review.md           # /review
│   └── bootstrap.md        # /bootstrap — génère CLAUDE.md projet
├── skills/
│   ├── rust-dev/           # Patterns Rust 2021, clippy, thiserror
│   ├── python-dev/         # FastAPI, pytest, type hints
│   └── running-app/        # Domaine métier mypacer/FFA
└── upstream/               # git submodules (repos tiers)
    └── anthropic-skills/   # Skills officiels Anthropic
```

## Installation

```bash
# Cloner dans le bon endroit
git clone <votre-remote> ~/.claude-config
cd ~/.claude-config

# Initialiser les submodules upstream
git submodule update --init

# Sauvegarder la config actuelle AVANT
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# Déployer
./install.sh
```

## Mise à jour

```bash
cd ~/.claude-config
./update.sh
```

## Switcher un upstream

```bash
cd ~/.claude-config

# Retirer l'ancien
git submodule deinit upstream/anthropic-skills
git rm upstream/anthropic-skills

# Ajouter le nouveau
git submodule add https://github.com/nouveau/repo.git upstream/nouveau-nom

# Adapter install.sh si le chemin interne change
# Redéployer
./install.sh
```

## Ajouter un agent ou skill

```bash
# Agent
cp template.md ~/.claude-config/agents/mon-agent.md
vim ~/.claude-config/agents/mon-agent.md
./install.sh

# Skill
mkdir ~/.claude-config/skills/mon-skill
vim ~/.claude-config/skills/mon-skill/SKILL.md
./install.sh

git add . && git commit -m "feat: add mon-agent / mon-skill"
```
