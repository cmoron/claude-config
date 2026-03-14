#!/usr/bin/env bash
# Hook PostToolUse : formate le fichier qui vient d'être écrit/édité
# Reçoit du JSON sur stdin avec tool_input.file_path

set -euo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)

# Rien à faire si pas de fichier ou fichier inexistant
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

EXT="${FILE##*.}"

case "$EXT" in
  py)
    black --quiet "$FILE" 2>/dev/null || true
    ruff check --fix --quiet "$FILE" 2>/dev/null || true
    ;;
  rs)
    rustfmt --edition 2021 "$FILE" 2>/dev/null || true
    ;;
  ts|tsx|js|jsx)
    prettier --write --log-level silent "$FILE" 2>/dev/null || true
    ;;
  json|css|html|md|yaml|yml)
    prettier --write --log-level silent "$FILE" 2>/dev/null || true
    ;;
esac

exit 0
