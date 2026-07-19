# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

Dépendance externe (binaire). Installation : voir `README.md` § Prérequis.
Projet : https://github.com/rtk-ai/rtk

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook
(`rtk hook claude`, PreToolUse Bash dans `settings.json`).
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead).

Si `rtk` n'est pas dans le PATH, le hook dégrade silencieusement (cf. garde
`command -v rtk` dans `settings.json`) — aucune commande Bash n'est bloquée.

⚠️ **Pipes consommant la sortie brute** : le hook réécrit aussi les commandes
dont la sortie alimente un autre programme (`git diff | git apply`, `… | patch`)
→ le résumé rtk casse le consommateur. Dans ce cas : `rtk proxy <cmd>`,
`--output=<fichier>`, ou éviter la pipe.

## Commandes natives rtk (hors de portée du hook)

Le hook réécrit les commandes standard (git, cargo, pytest…) mais ne peut pas
choisir une commande native rtk à ma place. À utiliser directement quand pertinent :

```bash
rtk read <file>       # lecture de code filtrée (60%)
rtk err <cmd>         # ne garde que les erreurs d'une commande
rtk log <file>        # logs dédupliqués avec compteurs
rtk json <file>       # structure JSON sans les valeurs
rtk summary <cmd>     # résumé d'une sortie verbeuse
```

⚠️ Ne jamais relancer `rtk init` / `rtk init --global` : il réinjecte ~140 lignes
dans CLAUDE.md, redondantes avec le hook (bloc retiré le 2026-07-07).
