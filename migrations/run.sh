#!/usr/bin/env bash
# Vibeboss migrations runner.
#
# Invoked by init.sh --update to apply structural shape adjustments to an
# existing workspace as it crosses release boundaries.
#
# Usage:
#   bash run.sh <WORKSPACE> <FROM_VERSION> <TO_VERSION>
#
# Behavior:
#   - Finds all sibling v<from>-to-v<to>.sh scripts in this directory.
#   - Selects those whose <from> >= FROM_VERSION and whose <to> <= TO_VERSION,
#     using simple lexical (string) comparison. This is good enough for
#     semver-like names provided no component crosses a single decimal digit
#     boundary (e.g. 0.10 < 0.2 lexically — see README).
#   - Runs the selected scripts in lex-sorted order, each receiving
#     $1 = WORKSPACE.
#   - Aborts on first nonzero exit. Prints a summary at the end.
#
# Exit codes:
#   0  success (including "no migrations applicable")
#   1  bad args
#   2  a migration failed

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <WORKSPACE> <FROM_VERSION> <TO_VERSION>" >&2
  exit 1
fi

WORKSPACE="$1"
FROM_VERSION="$2"
TO_VERSION="$3"

if [ -z "$WORKSPACE" ] || [ -z "$FROM_VERSION" ] || [ -z "$TO_VERSION" ]; then
  echo "error: all three arguments must be non-empty" >&2
  exit 1
fi

if [ ! -d "$WORKSPACE" ]; then
  echo "error: workspace does not exist: $WORKSPACE" >&2
  exit 1
fi

MIGRATIONS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Collect candidate migrations. Use nullglob so an empty match yields zero
# iterations rather than the literal pattern.
shopt -s nullglob
candidates=( "$MIGRATIONS_DIR"/v*-to-v*.sh )
shopt -u nullglob

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "No migration scripts found in $MIGRATIONS_DIR. Nothing to do."
  exit 0
fi

# Sort lexically. Bash sorts arrays via printf | sort.
IFS=$'\n' sorted=( $(printf '%s\n' "${candidates[@]}" | LC_ALL=C sort) )
unset IFS

applicable=()
for script in "${sorted[@]}"; do
  name="$(basename "$script")"
  # Parse: v<from>-to-v<to>.sh
  if [[ "$name" =~ ^v(.+)-to-v(.+)\.sh$ ]]; then
    m_from="${BASH_REMATCH[1]}"
    m_to="${BASH_REMATCH[2]}"
  else
    echo "skip: $name (does not match v<from>-to-v<to>.sh)"
    continue
  fi

  # Lex comparison: from >= FROM_VERSION AND to <= TO_VERSION.
  if [[ "$m_from" < "$FROM_VERSION" ]]; then
    continue
  fi
  if [[ "$m_to" > "$TO_VERSION" ]]; then
    continue
  fi

  applicable+=( "$script" )
done

if [ "${#applicable[@]}" -eq 0 ]; then
  echo "No migrations applicable for $FROM_VERSION -> $TO_VERSION."
  exit 0
fi

echo "Applying ${#applicable[@]} migration(s) for $FROM_VERSION -> $TO_VERSION:"
for script in "${applicable[@]}"; do
  echo "  - $(basename "$script")"
done

ran=()
for script in "${applicable[@]}"; do
  name="$(basename "$script")"
  echo ""
  echo "-> $name"
  if ! bash "$script" "$WORKSPACE"; then
    echo "error: migration failed: $name" >&2
    exit 2
  fi
  ran+=( "$name" )
done

echo ""
echo "Ran ${#ran[@]} migration(s): ${ran[*]}"
exit 0
