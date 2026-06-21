#!/usr/bin/env bash
# Hook Stop : backstop d'auto-amélioration (cf. CLAUDE.md § Auto-amélioration).
# Une fois par session, et seulement si du travail réel a eu lieu (working tree
# git modifié), rappelle à Claude de PROPOSER — en diff, jamais en commit auto —
# un skill neuf ou l'évolution d'un skill quand un pattern récurrent a émergé.
# Reçoit du JSON sur stdin : session_id, cwd, stop_hook_active.
# Dégrade en no-op (exit 0) à la moindre incertitude : ne bloque jamais à tort.

set -euo pipefail

INPUT=$(cat)

# Parse en un appel ; délimiteur tab (un cwd peut contenir des espaces).
PARSED=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print('\t'.join([
    str(d.get('session_id', '')),
    str(d.get('cwd', '')),
    str(d.get('stop_hook_active', False)).lower(),
]))
" 2>/dev/null || printf '\t\ttrue')

IFS=$'\t' read -r SESSION CWD ACTIVE <<<"$PARSED" || true

# Anti-boucle : on est déjà dans une continuation déclenchée par ce hook.
[ "${ACTIVE:-true}" = "true" ] && exit 0
[ -n "${SESSION:-}" ] || exit 0
[ -n "${CWD:-}" ] || CWD="$PWD"

# Une seule fois par session.
MARKER="${TMPDIR:-/tmp}/claude-reflect-${SESSION}"
[ -e "$MARKER" ] && exit 0

# Ne déclenche que si du travail réel a eu lieu (working tree modifié).
git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -n "$(git -C "$CWD" status --porcelain 2>/dev/null)" ] || exit 0

# Marque AVANT de bloquer : ne nudge qu'une fois quoi qu'il arrive ensuite.
: > "$MARKER"

# Contrat Stop hook propre : exit 0 + JSON {decision:block} sur stdout.
# (exit 2 forcerait le tour AUSSI, mais s'afficherait comme "Stop hook error".)
# reason = une seule chaîne ; les \n sont des échappements JSON littéraux (printf
# %s ne les interprète pas) — pas de guillemets/backslash dans le texte, donc
# aucun besoin de python (évite les soucis de locale sur argv en headless).
printf '{"decision":"block","reason":"%s"}\n' \
  "🔁 Backstop auto-amélioration (1×/session, cf. CLAUDE.md § Auto-amélioration).\n- Une procédure répétée (≥2-3×) ou une correction récurrente a-t-elle émergé cette session ? Si OUI → propose EN DIFF un skill neuf ou l'évolution d'un skill existant (jamais de commit auto ; revue avant écriture).\n- Sinon (mid-tâche ou rien à cristalliser) → dis-le en une ligne et continue."
exit 0
