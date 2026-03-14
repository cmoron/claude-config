#!/usr/bin/env bash
# install.sh : déploie la config claude-code via symlinks dans ~/.claude
# Idempotent — relancer sans risque après chaque modification

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

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

# Skills upstream Anthropic (si le submodule est initialisé)
ANTHROPIC_SKILLS="$CONFIG_DIR/upstream/anthropic-skills/skills"
if [ -d "$ANTHROPIC_SKILLS" ]; then
    for d in "$ANTHROPIC_SKILLS/"/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
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

echo ""
echo "✓ Déploiement terminé."
echo ""
echo "Redémarrez Claude Code pour prendre en compte les changements."
