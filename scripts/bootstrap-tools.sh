#!/usr/bin/env bash
# bootstrap-tools.sh : installe les outils CLI qui s'intègrent à Claude Code
# en s'auto-enregistrant (skills distribués comme packages, hors marketplace de
# plugins). Idempotent — uv tool install et graphify install détectent l'existant.

set -euo pipefail

if ! command -v uv >/dev/null 2>&1; then
    echo "✗ uv introuvable — installer uv d'abord (https://docs.astral.sh/uv/)"
    exit 1
fi

# graphify : transforme une codebase (code, docs, PDF, images) en knowledge
# graph interrogeable. Package PyPI : graphifyy ; commande : graphify.
# `graphify install` enregistre lui-même le skill dans ~/.claude/.
echo "→ graphify"
uv tool install graphifyy
graphify install
echo ""

echo "✓ Outils déployés."
