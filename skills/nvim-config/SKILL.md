---
name: nvim-config
description: Pour modifier la configuration Neovim de Cyril : plugins lazy.nvim, LSP, keybindings, formatters. Repo ~/src/nvim-config symlinkévers ~/.config/nvim.
---

# Neovim Config — ~/src/nvim-config

Configuration Neovim personnelle pour Neovim 0.11+. Symlink : `~/.config/nvim → ~/src/nvim-config/`

## Structure

```
~/src/nvim-config/
├── init.lua               # Configuration complète (fichier unique)
├── lazy-lock.json         # Lockfile des versions de plugins
├── stylua.toml            # Config formatter Lua
└── scripts/               # Scripts d'installation offline
```

Tout est dans `init.lua`, organisé en sections :
1. Settings de base (options vim.opt)
2. Autocmds (indentation par filetype, auto-reload)
3. Mappings globaux
4. Bootstrap lazy.nvim
5. Plugins (avec configs inline)
6. Configuration LSP (LspAttach autocmd)
7. Java (nvim-jdtls)

## Leader key

`Espace`

## Plugins installés

| Plugin | Rôle |
|--------|------|
| `lazy.nvim` | Gestionnaire de plugins |
| `gruvbox` | Colorscheme |
| `nvim-tree` | Explorateur de fichiers (F9) |
| `bufferline` | Onglets de buffers |
| `bufexplorer` | Gestionnaire de buffers (F12) |
| `lualine` | Statusline (thème gruvbox) |
| `which-key` | Découverte des raccourcis |
| `telescope` | Fuzzy finder (Ctrl-P, `<leader>g`) |
| `harpoon2` | Navigation rapide entre fichiers favoris |
| `gitsigns` | Indicateurs Git dans la marge |
| `vim-fugitive` | Interface Git (`:Git`) |
| `Comment.nvim` | Commentaires (`gcc`, `<leader>c<leader>`) |
| `nvim-autopairs` | Fermeture auto des parenthèses |
| `vim-sneak` | Navigation 2 caractères (`s{c}{c}`) |
| `conform.nvim` | Formatage (`<leader>f`) |
| `nvim-colorizer` | Affichage couleurs CSS |
| `indent-blankline` | Guides d'indentation |
| `nvim-treesitter` | Syntaxe avancée |
| `nvim-cmp` + sources | Autocomplétion (Ctrl-Space) |
| `nvim-lspconfig` | Configuration LSP |
| `trouble.nvim` | Diagnostics UI (`<leader>xx`) |
| `nvim-jdtls` | LSP Java (lazy, ft=java) |
| `copilot.vim` | GitHub Copilot |

## LSP configurés (Neovim 0.11+ API native)

```lua
vim.lsp.enable({ "pyright", "bashls", "ts_ls", "svelte", "rust_analyzer", "ruff" })
```

- `pyright` → Python (types, completion) — via `npm install -g pyright`
- `ruff` → Python (lint, format) — hover désactivé (conflit pyright) — via `uv tool install ruff`
- `bashls` → Bash — via `npm install -g bash-language-server`
- `ts_ls` → JavaScript/TypeScript — via `npm install -g typescript-language-server typescript`
- `svelte` → Svelte — via `npm install -g svelte-language-server`
- `rust_analyzer` → Rust — via `rustup component add rust-analyzer`
- Java → `nvim-jdtls` (chargé uniquement sur `ft=java`, binaire dans `~/.local/share/jdtls/`)

## Formatters (conform.nvim)

| Filetype | Formatter | Installation |
|----------|-----------|--------------|
| Python | `ruff_fix` + `ruff_format` | `uv tool install ruff` |
| Lua | `stylua` | `cargo install stylua` |
| JS/TS/HTML/CSS/JSON/YAML/MD | `prettier` | `npm install -g prettier` |
| XML | `xmllint` | `apt install libxml2-utils` |
| Tous | `trim_whitespace` | intégré |

Format manuel : `<leader>f` — pas de format automatique à la sauvegarde.

## Raccourcis clés (non-standards)

| Raccourci | Action |
|-----------|--------|
| `J` / `K` | Scroll rapide bas/haut (2/3 lignes) — ⚠️ K n'est PAS hover |
| `H` | Hover LSP (documentation) — remplace K |
| `<leader>n` / `<leader>N` | Diagnostic suivant/précédent |
| `<leader>e` | Diagnostic float |
| `<leader>rn` / `grn` | Rename symbole |
| `<leader>ca` / `gra` | Code action |
| `<C-p>` | Telescope find_files |
| `<leader>g` | Telescope live_grep |
| `<leader>p` | Telescope buffers |
| `<leader>a` | Harpoon: ajouter fichier |
| `<leader>h` | Harpoon: menu |
| `<leader>1-4` | Harpoon: aller au fichier 1-4 |
| `<leader>xx` | Trouble: toggle diagnostics |
| `<leader>f` | Format buffer |
| `<leader><CR>` | Reload config |
| `F9` | Toggle NvimTree |
| `F12` | BufExplorer |

## Ajouter un plugin

Ajouter dans le `require("lazy").setup({...})` en `init.lua` :
```lua
{
    "author/plugin-name",
    -- event = "VeryLazy",  -- chargement paresseux
    -- ft = "python",       -- uniquement pour ce filetype
    -- keys = { ... },      -- chargement au raccourci
    opts = { ... },         -- config simple via opts
    -- config = function() ... end,  -- config complexe
},
```

## Ajouter un serveur LSP

1. Installer le binaire (voir tableau LSP ci-dessus)
2. Ajouter dans `vim.lsp.enable({...})` en fin d'`init.lua`
3. Si config spécifique : `vim.lsp.config("nom_serveur", {...})` avant le `enable`

## Particularités WSL2

- Clipboard configuré via `clip.exe` / PowerShell pour éviter le freeze OSC 52
- Police : Hack Nerd Font Mono configurée dans Windows Terminal
- Snap recommandé pour installer la dernière version de Neovim

## Workflow de modification

```bash
# Editer directement (symlink actif)
nvim ~/src/nvim-config/init.lua

# Recharger sans quitter nvim
<leader><CR>

# Les changements sont dans le repo versionné
cd ~/src/nvim-config
git add -p && git commit
```
