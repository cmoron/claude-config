#!/usr/bin/env bash
# Claude Code statusLine command — mirrors shell PS1
# Receives JSON on stdin from Claude Code

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# ANSI colors
COLOR_RED="\e[91m"
COLOR_WHI="\e[97m"
COLOR_YEL="\e[93m"
COLOR_RES="\e[0m"

# Git branch (mirrors __git_ps1 output, skip optional locks)
git_branch=""
if git_dir=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --git-dir 2>/dev/null); then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
        || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" ($branch)"
    fi
fi

user=$(whoami)
host=$(hostname -s)

printf "${COLOR_RED}%s${COLOR_WHI}@%s ${COLOR_YEL}%s${COLOR_WHI}%s${COLOR_RES}" \
    "$user" "$host" "$cwd" "$git_branch"
