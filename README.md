# node-headers

A git mirror of official Node.js header tarballs (`node-vX.Y.Z-headers.tar.gz`),
one **git tag per Node.js version**, so native addon projects can pin their
header dependency with a plain `git submodule` — no installers, no
`node-gyp` network fetch, no extra tooling.

## How it works

- `scripts/sync.sh` reads `https://nodejs.org/dist/index.json`, compares it
  against the tags already in this repo, and for every missing version:
  downloads that version's headers tarball, extracts it, commits it as an
  **orphan commit** (no shared history with other versions), and tags it
  `vX.Y.Z`.
- `.github/workflows/sync.yml` runs that script every 6 hours (and on manual
  dispatch), so new Node.js releases show up as new tags automatically,
  with zero manual steps after setup.
- Orphan commits mean each tag is essentially an independent snapshot. A
  consumer who shallow-fetches a single tag only downloads that version's
  headers — not the accumulated history of every version ever added.

## One-time setup (do this once)

1. **Create the repo** on GitHub (e.g. `you/node-headers`), empty, with no
   README/license auto-generated (or delete their initial commit — it
   doesn't matter, `sync.sh` doesn't depend on any existing branch content).

2. **Clone it locally** and copy in these files (`scripts/sync.sh`,
   `.github/workflows/sync.yml`, this `README.md`):

   ```bash
   git clone https://github.com/you/node-headers.git
   cd node-headers
   # copy scripts/, .github/, README.md in here
   chmod +x scripts/sync.sh
   git add .
   git commit -m "Add sync automation"
   git push origin main
   ```

3. **Bootstrap the historical versions (v18 → now).** This is the exact
   same script the workflow runs later — you're just running it once by
   hand to seed history:

   ```bash
   # requires: git, curl, jq, tar (all standard on macOS/Linux; on Windows use WSL)
   MIN_MAJOR=18 bash scripts/sync.sh
   ```

   This will take a while the first time (it's downloading and tagging
   every released version from Node 18 onward — likely 100+ tags). It
   pushes tags as it goes via `git push origin --tags` at the end.

   Want to sanity-check first without pushing anything?

   ```bash
   DRY_RUN=true MIN_MAJOR=18 bash scripts/sync.sh
   ```

4. **Enable Actions write permissions**, since the workflow needs to push
   tags: in the repo, go to **Settings → Actions → General → Workflow
   permissions**, and select **"Read and write permissions"**. (The
   `permissions: contents: write` block in the workflow file requests this,
   but the repo-level setting must also allow it.)

5. **Push the workflow file** (if you haven't already) — as soon as it's on
   the default branch, it starts running on the cron schedule automatically.
   You can also trigger it manually anytime from the **Actions** tab
   (`workflow_dispatch`) to confirm it works before waiting for the next
   scheduled run.

That's it — from this point on, every new Node.js release becomes a new
tag within 6 hours, with no further action from you.

## Using it in a native addon project

```bash
git submodule add https://github.com/you/node-headers.git deps/node-headers
cd deps/node-headers
git fetch --depth 1 origin v22.5.1
git checkout v22.5.1
cd ../..
git add .gitmodules deps/node-headers
git commit -m "Pin Node headers to v22.5.1"
```

Then point your build at `deps/node-headers/include/node` (e.g. in
`binding.gyp`'s `include_dirs`, or your CMake `include_directories`).

To keep the submodule fetch shallow (recommended — avoids pulling every
other version's headers), configure it once:

```bash
git config -f .gitmodules submodule.deps/node-headers.shallow true
```

Bumping to a new Node version later is then just:

```bash
cd deps/node-headers
git fetch --depth 1 origin v22.6.0
git checkout v22.6.0
cd ../..
git add deps/node-headers
git commit -m "Bump Node headers to v22.6.0"
```

## Notes / things to decide for your fork

- **Which versions get included:** by default `MIN_MAJOR=18` and every
  released version (LTS and non-LTS, e.g. odd majors like 19/21/23) is
  tagged, since native addons may pin to any exact version. Adjust
  `MIN_MAJOR` in the workflow's default input if you want a different
  floor.
- **Tarball format:** this tries the `.tar.xz` headers tarball
  (`node-vX.Y.Z-headers.tar.xz`) first — it's ~100 KB vs ~10 MB for the
  gzip variant — and falls back to `.tar.gz` when `.tar.xz` is unavailable
  (older releases).
- **Repo size over time:** because each tag is an orphan commit, `git
  clone` **without** `--depth`/`--single-branch` will still eventually
  pull all objects reachable from all tags (git doesn't prune history you
  haven't asked it to skip). Consumers should always use `git fetch
  --depth 1 origin <tag>` as shown above, not a plain `git submodule add`
  default clone, to avoid downloading every version.
