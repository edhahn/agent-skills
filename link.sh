#!/bin/sh
# link.sh — symlink skills from this repo into agent skill directories.
#
# Usage:
#   ./link.sh                      Link every skill in this repo
#   ./link.sh skill-a skill-b      Link only the named skills
#   ./link.sh --dry-run            Print what would happen, change nothing
#   ./link.sh --force              Replace existing real directories (they are backed up)
#   ./link.sh --targets DIR[,DIR]  Override the destination skill directories
#
# Environment:
#   CLAUDE_SKILLS_DIR   default: $HOME/.claude/skills
#   CODEX_SKILLS_DIR    default: $HOME/.codex/skills
#
# Existing symlinks are repointed silently (the operation is idempotent).
# Existing real directories are left alone unless --force is given, in which
# case they are moved aside to <name>.bak.<timestamp> rather than deleted.

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

DRY_RUN=0
FORCE=0
TARGETS=""
SKILLS=""

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --force) FORCE=1 ;;
        --targets)
            [ $# -ge 2 ] || { echo "link.sh: --targets requires a value" >&2; exit 2; }
            TARGETS="$2"
            shift
            ;;
        --targets=*) TARGETS="${1#--targets=}" ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "link.sh: unknown option: $1" >&2; exit 2 ;;
        *) SKILLS="$SKILLS $1" ;;
    esac
    shift
done

if [ -z "$TARGETS" ]; then
    TARGETS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills},${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
fi

# Default to every directory containing a SKILL.md.
if [ -z "$SKILLS" ]; then
    for dir in "$REPO_DIR"/*/; do
        [ -f "${dir}SKILL.md" ] || continue
        SKILLS="$SKILLS $(basename "$dir")"
    done
fi

if [ -z "$SKILLS" ]; then
    echo "link.sh: no skills found in $REPO_DIR" >&2
    exit 1
fi

# Validate up front so a typo doesn't half-apply.
for skill in $SKILLS; do
    if [ ! -f "$REPO_DIR/$skill/SKILL.md" ]; then
        echo "link.sh: no such skill: $skill (expected $REPO_DIR/$skill/SKILL.md)" >&2
        exit 1
    fi
done

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  would: $*"
    else
        "$@"
    fi
}

stamp=$(date +%Y%m%d%H%M%S)
skipped=0

# Iterate targets by rewriting commas to spaces; skill and target paths here are
# repo directory names and configured paths, not arbitrary input.
IFS=,
set -f
for target in $TARGETS; do
    IFS=' '
    set +f
    [ -n "$target" ] || continue
    echo "$target"

    if [ ! -d "$target" ]; then
        run mkdir -p "$target"
    fi

    for skill in $SKILLS; do
        src="$REPO_DIR/$skill"
        dest="$target/$skill"

        if [ -L "$dest" ]; then
            current=$(readlink "$dest")
            if [ "$current" = "$src" ]; then
                echo "  ok       $skill (already linked)"
                continue
            fi
            echo "  relink   $skill (was -> $current)"
            run rm -f "$dest"
        elif [ -e "$dest" ]; then
            if [ "$FORCE" -eq 1 ]; then
                echo "  replace  $skill (existing directory backed up to $skill.bak.$stamp)"
                run mv "$dest" "$dest.bak.$stamp"
            else
                echo "  SKIP     $skill (real directory exists; use --force to replace)"
                skipped=$((skipped + 1))
                continue
            fi
        else
            echo "  link     $skill"
        fi

        run ln -s "$src" "$dest"
    done

    IFS=,
    set -f
done
IFS=' '
set +f

if [ "$DRY_RUN" -eq 1 ]; then
    echo
    echo "Dry run — nothing was changed."
fi

if [ "$skipped" -gt 0 ]; then
    echo
    echo "$skipped skill(s) skipped because a real directory already exists."
    echo "Re-run with --force to replace them (originals are backed up, not deleted)."
fi
