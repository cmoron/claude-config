#!/usr/bin/env bash
# update.sh : met à jour les submodules upstream et redéploie les symlinks

set -euo pipefail

# Bascule agent-config : ce depot n'est plus la source deployee.
source "$HOME/src/agent-config/scripts/legacy-installer-guard.sh" || exit $?

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$CONFIG_DIR"

echo "→ Mise à jour des submodules upstream..."
git submodule update --remote --merge

echo ""
echo "→ Redéploiement des symlinks..."
"$CONFIG_DIR/install.sh"

echo ""
echo "→ Statut git :"
git status --short

echo ""
echo "Si des submodules ont été mis à jour, committez :"
echo "  git add . && git commit -m 'chore: update upstream submodules'"
