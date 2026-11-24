#!/bin/sh
# platform: host-agnostic
# A line repo is forked to make the next line. Every value that names a line must be derived from
# UPSTREAM_VERSION, or the fork silently ships the old line's names. Only the allowlist below may
# name another Go line, each for the reason given.
#
# Allowlist additions beyond the ones the plan's task brief specified verbatim:
# - tests/line-literals-test.sh (this file): once tracked, its own allowlist regexes below
#   necessarily spell out old-line tokens (e.g. golang-126, 1.26) to match against -- excluding
#   its own source is the guard declining to flag itself, not silencing a class of hits elsewhere.
# - INGREDIENTS.md:28,30,34 (1.27): the "Why the bootstrap Go is capped" section tells this repo's own
#   real incident (a mergeable Renovate PR that would have built 1.26 with a 1.27 compiler) -- the
#   numbers are the story, not this repo's identity, so they are not rewritten.
# - .github/renovate.json and INGREDIENTS.md, 1.27: the cap, just below the next Go minor.
# - CLAUDE.md, golang-127: the sibling line, forked from this one, named as such.
# - tests/port-md-test.sh, go127: the incident that test exists for happened in golang-127's port.
set -eu
R="$(cd "$(dirname "$0")/.." && pwd)"
cd "$R"
U="$(tr -d '[:space:]' < UPSTREAM_VERSION)"
minor="$(printf '%s' "$U" | cut -d. -f2)"
thisid="1$minor"
# One match per output line (file:lineno:match), so a line naming both this line and another is
# still caught, and the allowlist can name exact matches rather than whole lines.
# platform: BSD grep 2.5.1 (10.9) prints a line's second and later -o matches without the file:lineno: prefix; awk restores it.
hits="$(git ls-files -z \
  | xargs -0 grep -noE '(go-?|golang-)1[0-9]{2}\b|\b1\.2[0-9]\b' 2>/dev/null \
  | awk '/^[^:]*:[0-9]+:/ { p = $0; sub(/:[0-9]+:.*$/, "", p); q = $0; sub(/^[^:]*:/, "", q); sub(/:.*$/, "", q); p = p ":" q ":"; print; next } { print p $0 }' \
  | grep -vE ":(go-?|golang-)$thisid\$|:1\\.$minor\$" \
  | grep -vE '^tests/line-literals-test\.sh:' \
  | grep -vE '^(patches|release-notes|vendor)/' \
  | grep -vE '^PORT\.md:' \
  | grep -vE '^tests/go-src-sha256-test\.sh:' \
  | grep -vE '^CLAUDE\.md:[0-9]+:golang-127$' \
  | grep -vE '^tests/port-md-test\.sh:[0-9]+:go127$' \
  | grep -vE '^(\.github/renovate\.json|INGREDIENTS\.md):[0-9]+:1\.27$' \
  | grep -vE ':[0-9]+:1\.24$' \
  | grep -vE '^INGREDIENTS\.md:(28|30|34):1\.27$' \
  || true)"
[ -z "$hits" ] || { printf 'FAIL: these name a Go line other than %s -- derive them from UPSTREAM_VERSION, or allowlist them here with the reason:\n%s\n' "$U" "$hits"; exit 1; }
echo "PASS: line-literals"
