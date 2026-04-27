# claude-config

Configuration personnelle de Claude Code — agents, commandes, skills, hooks et scripts.

## Prérequis

```bash
# Obligatoires
claude   # Claude Code CLI
git
jq       # utilisé par le statusline (apt install jq / brew install jq)
bun      # runtime + package manager (https://bun.sh)
rg       # ripgrep (apt install ripgrep / brew install ripgrep)

# Par stack
uv       # Python (remplace pip/venv/poetry)
cargo    # Rust
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

### Agents custom (`~/.claude/agents/`)

Sélectionnés automatiquement par Claude selon le contexte. La liste est volontairement courte : tout ce qui peut être couvert par un plugin l'est.

| Domaine | Agents |
|---------|--------|
| Architecture | `software-architect` |
| Développement | `fullstack-developer`, `api-designer`, `ui-designer`, `python-pro`, `rust-pro` |

Bibliothèque de référence : `upstream/awesome-claude-code-subagents/` (141 agents disponibles à recopier au besoin).

### Commandes slash custom (`~/.claude/commands/`)

| Commande | Description |
|----------|-------------|
| `/commit` | Génère un commit message Conventional Commits |

Le reste (Plan, Architect, TDD, Debug, Review, Audit, Deploy, Document, Migrate…) est fourni par le plugin `superpowers`.

### Skills custom (`~/.claude/skills/`)

- `claude-config` — modifier cette config
- `nvim-config` — modifier la config Neovim (`~/src/nvim-config`)
- `linear` — gérer les projets Linear DecaSaaS
- `notion` — base documentaire DecaSaaS
- `openclaw` — VM NAS locale Nestor/openclaw
- `mvp` — création MVP/POC rapide avec stacks préférées
- `grill-me` — interview contradictoire sur un plan/design

### Hooks et scripts

| Hook | Script | Déclencheur |
|------|--------|-------------|
| Format on save | `scripts/format-on-save.sh` | Après Write/Edit |
| Protection `.env` | `scripts/protect-env.sh` | Avant Write/Edit |
| Notification sonore | `scripts/notify-sound.sh` | Stop / Notification |
| Statusline | `bunx ccstatusline` | UserPromptSubmit / Skill |
| RTK token saver | `rtk hook claude` | Avant Bash |

### Plugins (à installer manuellement)

Les plugins ne peuvent pas être installés par script — ils passent par le registre Claude Code (`/plugin install`) :

**Officiels (`claude-plugins-official`)**
```
typescript-lsp           # LSP TypeScript
pyright-lsp              # LSP Python
rust-analyzer-lsp        # LSP Rust
jdtls-lsp                # LSP Java
superpowers              # 14 skills méthodologie (Plan/TDD/Debug/Review/Audit/Deploy…)
security-guidance        # scan passif vulnérabilités
context7                 # doc à jour des libs
github                   # workflow PR/issue
playwright               # tests browser
claude-md-management     # maintenance auto du CLAUDE.md projet
frontend-design          # design system / UI
skill-creator            # méta-skill pour créer/améliorer des skills
```

**Tiers**
```
mgrep@Mixedbread-Grep    # recherche sémantique + web
claude-mem@thedotmack    # mémoire persistante cross-session
```

## ⚠️ Note sur les permissions

`settings.json` utilise `defaultMode: bypassPermissions` — Claude n'ask pas de confirmation pour les actions locales. Les opérations dangereuses (rm -rf, force push, sudo, etc.) sont bloquées par la liste `deny`. Adapte selon ton niveau de confiance.

## Structure

```
.
├── agents/          # agents spécialisés non couverts par les plugins
├── commands/        # commandes slash custom
├── skills/          # skills custom
├── scripts/         # hooks shell
├── upstream/
│   ├── anthropic-skills/              # submodule : skills officiels
│   └── awesome-claude-code-subagents/ # submodule : bibliothèque 141 agents
├── CLAUDE.md        # instructions globales pour tous les projets
├── settings.json    # permissions, hooks, plugins
├── install.sh       # déploie la config via symlinks dans ~/.claude/
└── update.sh        # pull + submodules + redéploiement
```
