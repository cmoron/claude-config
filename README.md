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

`install.sh` fait deux choses :
1. **Symlinke** la config (CLAUDE.md, settings.json, agents, commands, skills) dans `~/.claude/` — versionné dans ce repo. Purge au passage les symlinks morts ou orphelins (déploiement déclaratif : on repart de l'état du repo)
2. **Bootstrap les plugins** via `scripts/bootstrap-plugins.sh` (si `claude` est dans le PATH) — enregistre les marketplaces et installe les plugins listés dans `enabledPlugins` de `settings.json`

Le bootstrap est idempotent : on peut relancer sans risque, les plugins déjà installés sont détectés.

Si la CLI `claude` n'était pas dispo lors du premier `install.sh`, lancer après installation :
```bash
./scripts/bootstrap-plugins.sh
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
| Développement | `fullstack-developer` |

Le design UI est couvert par le plugin `frontend-design`.

Besoin d'un agent supplémentaire : s'inspirer de [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) et recopier l'agent adapté dans `agents/`.

### Commandes slash custom (`~/.claude/commands/`)

| Commande | Description |
|----------|-------------|
| `/commit` | Génère un commit message Conventional Commits |
| `/autoship <desc>` | Produit une petite feature/fix en autonomie totale (build loop + ship) |

Le reste (Plan, Architect, TDD, Debug, Review, Audit, Document, Migrate…) est fourni par le plugin `superpowers` ; le déploiement par le skill custom `deployment`.

### Skills custom (`~/.claude/skills/`)

- `claude-config` — modifier cette config
- `nvim-config` — modifier la config Neovim (`~/src/nvim-config`)
- `linear` — gérer les projets Linear DecaSaaS
- `openclaw` — VM NAS locale Nestor/openclaw
- `mvp` — création MVP/POC rapide avec stacks préférées
- `grill-me` — interview contradictoire sur un plan/design
- `stack-python` — conventions Python (uv, ruff, mypy, pytest)
- `stack-ts` — conventions TypeScript (bun)
- `stack-rust` — conventions Rust (clippy, thiserror/anyhow)
- `api-design` — conception d'API REST/GraphQL
- `deployment` — déploiement CI/CD (GitHub Actions, Docker, serveurs Debian/Ubuntu)
- `autoship` — production autonome d'une petite feature/fix (orchestrateur map→ship)

Les skills Anthropic upstream déployés sont curés via une allowlist dans
`install.sh` (`ANTHROPIC_ALLOWLIST`) — on ne symlinke que les skills utiles.

### Hooks et scripts

| Hook | Script | Déclencheur |
|------|--------|-------------|
| Format on save | `scripts/format-on-save.sh` | Après Write/Edit |
| Protection `.env` | `scripts/protect-env.sh` | Avant Write/Edit |
| Notification sonore | `scripts/notify-sound.sh` | Stop / Notification |
| Statusline | `bunx ccstatusline` | UserPromptSubmit / Skill |
| RTK token saver | `rtk hook claude` | Avant Bash |

### Plugins (auto-installés par `install.sh`)

Les plugins sont déclarés dans `settings.json` (`enabledPlugins`) et installés automatiquement par `scripts/bootstrap-plugins.sh` via la CLI `claude plugin install`.

**Officiels (`claude-plugins-official`)** — 11 plugins
| Plugin | Rôle |
|--------|------|
| `typescript-lsp` | LSP TypeScript |
| `pyright-lsp` | LSP Python |
| `rust-analyzer-lsp` | LSP Rust |
| `jdtls-lsp` | LSP Java |
| `superpowers` | 14 skills méthodologie (Plan/TDD/Debug/Review/Audit/Document…) |
| `security-guidance` | Scan passif vulnérabilités |
| `context7` | Doc à jour des libs |
| `playwright` | Tests browser |
| `claude-md-management` | Maintenance auto du CLAUDE.md projet |
| `frontend-design` | Design system / UI |
| `skill-creator` | Méta-skill pour créer/améliorer des skills |

**Tiers** — 2 plugins
| Plugin | Marketplace | Rôle |
|--------|-------------|------|
| `mgrep` | `mixedbread-ai/mgrep` | Recherche sémantique + web |
| `claude-mem` | `thedotmack/claude-mem` | Mémoire persistante cross-session |

Pour ajouter un plugin : éditer `enabledPlugins` dans `settings.json` puis relancer `./scripts/bootstrap-plugins.sh`.

## ⚠️ Note sur les permissions

`settings.json` utilise `defaultMode: bypassPermissions` — Claude n'ask pas de confirmation pour les actions locales. Les opérations dangereuses (rm -rf, force push, sudo, etc.) sont bloquées par la liste `deny`. Adapte selon ton niveau de confiance.

## Structure

```
.
├── agents/          # agents spécialisés non couverts par les plugins
├── commands/        # commandes slash custom
├── skills/          # skills custom
├── scripts/         # hooks shell + bootstrap-plugins.sh
├── upstream/
│   └── anthropic-skills/              # submodule : skills officiels Anthropic
├── CLAUDE.md        # instructions globales pour tous les projets
├── settings.json    # permissions, hooks, plugins
├── install.sh       # déploie la config via symlinks dans ~/.claude/
└── update.sh        # pull + submodules + redéploiement
```
