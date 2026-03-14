# claude-config

Configuration personnelle de Claude Code — agents, commandes, skills, hooks et scripts.

## Prérequis

```bash
# Obligatoires
claude   # Claude Code CLI
git
jq       # utilisé par le statusline (apt install jq / brew install jq)
node     # pour ccstatusline et mgrep (npx)
rg       # ripgrep — utilisé par le Grep intégré de Claude (apt install ripgrep / brew install ripgrep)
mgrep    # recherche sémantique + web synthétisé : npm install -g mgrep

# Par stack
uv       # Python (remplace pip/venv/poetry)
cargo    # Rust
pnpm     # Node/TypeScript
```

## Installation

```bash
git clone --recurse-submodules https://github.com/<toi>/claude-config ~/src/claude-config
cd ~/src/claude-config
./install.sh
```

Si tu as cloné sans `--recurse-submodules` :

```bash
git submodule update --init
```

## Mise à jour

```bash
./update.sh
```

## Ce qui est déployé

### Agents (`~/.claude/agents/`)

Sélectionnés et invoqués automatiquement par Claude selon le contexte.

| Domaine | Agents |
|---------|--------|
| Architecture | `software-architect`, `architect-reviewer` |
| Développement | `fullstack-developer`, `api-designer`, `ui-designer`, `python-pro`, `rust-pro` |
| Qualité | `code-reviewer`, `debugger`, `security-auditor`, `penetration-tester`, `compliance-auditor` |
| Infra & ops | `devops`, `docker-expert`, `deployment-engineer`, `sre-engineer`, `it-ops-orchestrator` |

Bibliothèque de référence : `upstream/awesome-claude-code-subagents/` (141 agents disponibles).

### Commandes slash (`~/.claude/commands/`)

| Commande | Description |
|----------|-------------|
| `/bootstrap` | Génère un `CLAUDE.md` pour le projet courant |
| `/implement <feature>` | Implémente avec tests (explore → plan → TDD → commit) |
| `/review` | Revue du diff courant, priorisée par sévérité |
| `/commit` | Génère un commit message Conventional Commits |

### Skills (`~/.claude/skills/`)

- `python-dev` — stack Python : FastAPI, uv, ruff, mypy, pytest
- `rust-dev` — stack Rust 2021 : clippy strict, error handling idiomatique
- `running-app` — domaine métier running/athlétisme (mypacer, bases_athle)

Les skills Anthropic officiels sont déployés depuis `upstream/anthropic-skills/`.

### Hooks et scripts

| Hook | Script | Déclencheur |
|------|--------|-------------|
| Format on save | `scripts/format-on-save.sh` | Après Write/Edit |
| Protection `.env` | `scripts/protect-env.sh` | Avant Write/Edit |
| Bell notification | `scripts/bell.sh` | Stop / Notification |
| Statusline | `scripts/statusline.sh` | ccstatusline |

### Plugins (à installer manuellement)

Les plugins ne peuvent pas être installés par script — ils passent par le registre Claude Code :

```
mgrep@Mixedbread-Grep       # recherche sémantique et web
claude-mem@thedotmack        # mémoire persistante cross-session
typescript-lsp@claude-plugins-official  # LSP TypeScript
```

## ⚠️ Note sur les permissions

`settings.json` utilise `defaultMode: bypassPermissions` — Claude n'ask pas de confirmation pour les actions locales. Les opérations dangereuses (rm -rf, force push, sudo, etc.) sont bloquées par la liste `deny`. Adapte selon ton niveau de confiance.

## Structure

```
.
├── agents/          # 19 agents spécialisés
├── commands/        # 4 commandes slash
├── skills/          # 3 skills custom (+ anthropic via submodule)
├── scripts/         # hooks shell
├── upstream/
│   ├── anthropic-skills/              # submodule : skills officiels
│   └── awesome-claude-code-subagents/ # submodule : bibliothèque 141 agents
├── CLAUDE.md        # instructions globales pour tous les projets
├── settings.json    # permissions, hooks, plugins
├── install.sh       # déploie la config via symlinks dans ~/.claude/
└── update.sh        # pull + submodules + redéploiement
```
