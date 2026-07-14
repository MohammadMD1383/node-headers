#!/usr/bin/env bash
#
# sync.sh
#
# Scans https://nodejs.org/dist/index.json for released Node.js versions,
# compares against existing git tags in this repo, and for every version
# that is missing:
#   1. Downloads the headers tarball for that version
#   2. Creates an ORPHAN commit (no shared history with other versions)
#      containing just that version's extracted headers at repo root
#   3. Tags that commit vX.Y.Z
#   4. Pushes the new tag
#
# Orphan commits keep each tag's history independent, so a consumer doing
# a shallow single-tag fetch only downloads that one version's headers,
# not the entire repo's accumulated history.
#
# Requires: git, curl, jq, tar
# Env vars:
#   MIN_MAJOR       - lowest major version to include (default: 18)
#   INCLUDE_ALL     - (unused; odd majors are always included)
#   DRY_RUN         - "true" to print what would happen without pushing

set -euo pipefail

MIN_MAJOR="${MIN_MAJOR:-18}"
INCLUDE_ALL="${INCLUDE_ALL:-true}"
DRY_RUN="${DRY_RUN:-false}"

REPO_DIR="$(pwd)"
BOT_NAME="node-headers-bot"
BOT_EMAIL="node-headers-bot@users.noreply.github.com"

log() { echo "[sync] $*" >&2; }

CURL_OPTS=(-sf --retry 3 --retry-delay 5 --connect-timeout 30)

command -v jq >/dev/null || { log "jq is required"; exit 1; }

log "Fetching Node.js release index..."
INDEX_JSON="$(curl "${CURL_OPTS[@]}" https://nodejs.org/dist/index.json)"

log "Fetching existing tags..."
git fetch --tags --force --quiet || true
EXISTING_TAGS="$(git tag -l 'v*' | sed 's/^v//' | sort -u)"

# Build the list of candidate versions >= MIN_MAJOR, newest last so tags
# are created in ascending order (nicer git tag -l output, not functionally
# required since each commit is an orphan).
CANDIDATES="$(echo "$INDEX_JSON" | jq -r --argjson minmajor "$MIN_MAJOR" '
  [.[] | select((.version | ltrimstr("v") | split(".")[0] | tonumber) >= $minmajor)]
  | sort_by(.version)
  | .[].version
' | sed 's/^v//')"

NEW_COUNT=0

while IFS= read -r VERSION; do
  [ -z "$VERSION" ] && continue

  if echo "$EXISTING_TAGS" | grep -qx "$VERSION"; then
    continue
  fi

  URL="https://nodejs.org/dist/v${VERSION}/node-v${VERSION}-headers.tar.gz"

  if ! curl "${CURL_OPTS[@]}" -I "$URL" > /dev/null 2>&1; then
    log "No headers tarball for v$VERSION (skipping, e.g. too old or unreleased on this channel)"
    continue
  fi

  log "New version found: v$VERSION"
  NEW_COUNT=$((NEW_COUNT + 1))

  if [ "$DRY_RUN" = "true" ]; then
    log "[dry-run] would create tag v$VERSION"
    continue
  fi

  WORKDIR="$(mktemp -d)"
  TARBALL="$WORKDIR/headers.tar.gz"
  EXTRACT_DIR="$WORKDIR/extract"
  WORKTREE_DIR="$WORKDIR/wt"

  mkdir -p "$EXTRACT_DIR"
  curl "${CURL_OPTS[@]}" -L "$URL" -o "$TARBALL"
  tar -xzf "$TARBALL" -C "$EXTRACT_DIR" --strip-components=1

  # Record provenance
  cat > "$EXTRACT_DIR/.node-headers-source.json" <<EOF
{
  "version": "v${VERSION}",
  "source_url": "${URL}",
  "synced_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  TMP_BRANCH="sync-tmp-${VERSION}"
  git worktree add --detach "$WORKTREE_DIR" --quiet

  (
    cd "$WORKTREE_DIR"
    git checkout --orphan "$TMP_BRANCH" --quiet
    git rm -rf . --quiet > /dev/null 2>&1 || true
    cp -a "$EXTRACT_DIR/." .
    git add -A
    git -c user.name="$BOT_NAME" -c user.email="$BOT_EMAIL" \
      commit -m "Node.js v${VERSION} headers" --quiet
    git tag "v${VERSION}"
  )

  cd "$REPO_DIR"
  git worktree remove "$WORKTREE_DIR" --force
  git branch -D "$TMP_BRANCH" --quiet
  rm -rf "$WORKDIR"

  log "Tagged v${VERSION}"
done <<< "$CANDIDATES"

if [ "$NEW_COUNT" -eq 0 ]; then
  log "No new versions. Nothing to do."
  exit 0
fi

if [ "$DRY_RUN" = "true" ]; then
  log "Dry run complete. $NEW_COUNT version(s) would have been added."
  exit 0
fi

log "Pushing $NEW_COUNT new tag(s)..."
git push origin --tags

log "Done."
