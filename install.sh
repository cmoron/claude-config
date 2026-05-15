#!/usr/bin/env bash
# install.sh : déploie la config claude-code via symlinks dans ~/.claude
# Idempotent — relancer sans risque après chaque modification

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Réconciliation : supprime d'un dossier les symlinks morts ou pointant dans ce
# repo. Garantit qu'une ressource retirée du repo ne laisse pas d'orphelin dans
# ~/.claude (déploiement déclaratif — on repart de l'état du repo).
prune_managed_links() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    for link in "$dir"/*; do
        [ -L "$link" ] || continue
        if [ ! -e "$link" ] || [[ "$(readlink "$link")" == "$CONFIG_DIR"* ]]; then
            rm -f "$link"
            echo "  ✗ purgé : ${link#$CLAUDE_DIR/}"
        fi
    done
}

echo "→ Config source  : $CONFIG_DIR"
echo "→ Cible          : $CLAUDE_DIR"
echo ""

# Créer les dossiers cibles si nécessaires
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

# Rendre les scripts exécutables
chmod +x "$CONFIG_DIR/scripts/"*.sh

# Symlinks fichiers principaux
for f in CLAUDE.md settings.json; do
    if [ -f "$CONFIG_DIR/$f" ]; then
        ln -sf "$CONFIG_DIR/$f" "$CLAUDE_DIR/$f"
        echo "  ✓ ~/.claude/$f"
    fi
done

# Réconciliation : purge les symlinks gérés avant de recréer l'état courant
prune_managed_links "$CLAUDE_DIR/agents"
prune_managed_links "$CLAUDE_DIR/commands"
prune_managed_links "$CLAUDE_DIR/skills"

# Agents : un symlink par fichier .md
for f in "$CONFIG_DIR/agents/"*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    ln -sf "$f" "$CLAUDE_DIR/agents/$name"
    echo "  ✓ ~/.claude/agents/$name"
done

# Commands : un symlink par fichier .md
for f in "$CONFIG_DIR/commands/"*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    ln -sf "$f" "$CLAUDE_DIR/commands/$name"
    echo "  ✓ ~/.claude/commands/$name"
done

# Skills personnels : un symlink par dossier
for d in "$CONFIG_DIR/skills/"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    ln -sfn "$d" "$CLAUDE_DIR/skills/$name"
    echo "  ✓ ~/.claude/skills/$name"
done

# Skills upstream Anthropic — allowlist explicite. On ne déploie que les skills
# réellement utiles, pas tout le submodule (chaque description déployée coûte
# des tokens à chaque session). skill-creator et frontend-design sont exclus :
# déjà fournis par les plugins du même nom.
ANTHROPIC_SKILLS="$CONFIG_DIR/upstream/anthropic-skills/skills"
ANTHROPIC_ALLOWLIST=(claude-api mcp-builder webapp-testing doc-coauthoring docx pdf pptx xlsx)
if [ -d "$ANTHROPIC_SKILLS" ]; then
    for name in "${ANTHROPIC_ALLOWLIST[@]}"; do
        d="$ANTHROPIC_SKILLS/$name"
        [ -d "$d" ] || { echo "  ⚠  skill anthropic introuvable : $name"; continue; }
        # Ne pas écraser un skill personnel de même nom
        if [ ! -e "$CLAUDE_DIR/skills/$name" ]; then
            ln -sfn "$d" "$CLAUDE_DIR/skills/$name"
            echo "  ✓ ~/.claude/skills/$name (anthropic)"
        fi
    done
else
    echo "  ℹ  Submodule anthropic-skills absent — lancez :"
    echo "     cd $CONFIG_DIR && git submodule update --init"
fi

# Config ccstatusline : symlink du dossier
mkdir -p "$HOME/.config"
# Si c'est un vrai dossier (pas déjà un symlink), le remplacer
if [ -d "$HOME/.config/ccstatusline" ] && [ ! -L "$HOME/.config/ccstatusline" ]; then
    rm -rf "$HOME/.config/ccstatusline"
fi
ln -sfn "$CONFIG_DIR/config/ccstatusline" "$HOME/.config/ccstatusline"
echo "  ✓ ~/.config/ccstatusline"

echo ""

# Plugins : marketplaces + installation depuis enabledPlugins
if command -v claude >/dev/null 2>&1; then
    echo "→ Plugins (claude CLI détectée)"
    "$CONFIG_DIR/scripts/bootstrap-plugins.sh"
else
    echo "  ℹ  claude CLI introuvable — lancer plus tard :"
    echo "     $CONFIG_DIR/scripts/bootstrap-plugins.sh"
fi

echo ""

# Outils CLI intégrés à Claude Code (graphify…), distribués comme packages
if command -v uv >/dev/null 2>&1; then
    echo "→ Outils (uv détecté)"
    "$CONFIG_DIR/scripts/bootstrap-tools.sh"
else
    echo "  ℹ  uv introuvable — lancer plus tard :"
    echo "     $CONFIG_DIR/scripts/bootstrap-tools.sh"
fi

echo ""
echo "✓ Déploiement terminé."
echo ""
echo "Redémarrez Claude Code pour prendre en compte les changements."
