#!/usr/bin/env bash
cd "$1" || exit

if git rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Status indicators
    dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        dirty="*"
    fi

    echo " $branch$dirty"
fi

