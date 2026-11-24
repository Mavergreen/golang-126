#!/bin/sh
# platform: host-agnostic
#   usage: sh tests/port-guards.sh
#          Runs golang-port's guards over this line's own files: the port resolved by build/port.sh (GOLANG_PORT_DIR, or the
#          pinned release), then LINE_ROOT=<this repo> sh "$PORT_DIR/tests/prefix-check.sh" -- the derived prefixes for this
#          line, and no file here naming a prefix the family has left. Skips (77) without shipyard's scripts, which port.sh needs.
set -eu
R="$(cd "$(dirname "$0")/.." && pwd)"
. "$R/build/msc.sh"
[ -f "${SHIPYARD_SCRIPTS:-}/fetch-release-pkg.sh" ] || { echo "no shipyard fetch-release-pkg.sh in SHIPYARD_SCRIPTS (${SHIPYARD_SCRIPTS:-unset}) -- skipping"; exit 77; }
PORT_DIR="$(sh "$R/build/port.sh")" || { echo "FAIL: build/port.sh could not resolve the port, so its guards cannot run over this line"; exit 1; }
[ -f "$PORT_DIR/tests/prefix-check.sh" ] || { echo "FAIL: the port at $PORT_DIR has no tests/prefix-check.sh"; exit 1; }
# spec: golang-port tests/prefix-check.sh -- its LINE_ROOT mode scans every file under the line, so it is handed a copy of the line's
#       files: the tracked files when git is there (a checkout's gitignored docs/ and .superpowers/ are history that ships nowhere and
#       may name the old prefixes), else every file but .git. Either way without release-notes/<version>.md: each is the published
#       notes of a release this line already shipped (the earliest name their old install prefix), history that is not rewritten.
T="$(mktemp -d "${TMPDIR:-/tmp}/port-guards.XXXXXX")"; trap 'rm -rf "$T"' EXIT
if command -v git >/dev/null 2>&1 && git -C "$R" rev-parse --git-dir >/dev/null 2>&1; then
  ( cd "$R" && git ls-files ) > "$T/.files"
else
  ( cd "$R" && find . -path ./.git -prune -o -type f -print | sed 's|^\./||' ) > "$T/.files"
fi
mkdir "$T/line"
grep -v -E '^release-notes/[0-9][^/]*\.md$' "$T/.files" | ( cd "$R" && tr '\n' '\0' | xargs -0 tar -cf - ) | ( cd "$T/line" && tar -xf - )
[ -f "$R/VERSION" ] && cp "$R/VERSION" "$T/line/VERSION" || sh "$R/build/version.sh" auto | sed -n 's/^FULL=//p' > "$T/line/VERSION"
line="$T/line"
LINE_ROOT="$line" sh "$PORT_DIR/tests/prefix-check.sh" || { echo "FAIL: golang-port's prefix-check fails on this line"; exit 1; }
echo "PASS: port-guards"
