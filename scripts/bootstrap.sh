#!/usr/bin/env bash
#
# bootstrap.sh
#
# One-time seeding of historical Node.js header tags (v18 → latest).
#
# This is a thin wrapper around sync.sh for the initial setup:
# it pins MIN_MAJOR to 18 (the same default sync.sh already uses)
# and exists so the README's bootstrap step reads as a single
# unambiguous command ("bash scripts/bootstrap.sh").
#
# Usage:
#   bash scripts/bootstrap.sh                    # real run (downloads + tags + pushes)
#   DRY_RUN=true bash scripts/bootstrap.sh       # list what would be tagged, no side effects

set -euo pipefail
export MIN_MAJOR="${MIN_MAJOR:-18}"
exec "$(dirname "$0")"/sync.sh
