#!/usr/bin/env bash
# Hook PreToolUse : bloque les écritures sur les fichiers d'env sensibles
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

[ -z "$FILE" ] && exit 0

# Liste des patterns protégés
BASENAME=$(basename "$FILE")
case "$BASENAME" in
  .env|.env.local|.env.production|.env.staging|.env.prod)
    echo "⛔ Fichier protégé : $FILE" >&2
    echo "   Modifiez-le manuellement si nécessaire." >&2
    exit 2
    ;;
esac

exit 0
