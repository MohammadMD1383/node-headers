<div align="center">

# 📦 node-headers

**Zero-install Node.js C/C++ headers for native addons**  
One `git tag` per version · Auto-synced · Plain `git submodule`

  <a href="https://github.com/MohammadMD1383/node-headers/actions/workflows/sync.yml">
    <img src="https://github.com/MohammadMD1383/node-headers/actions/workflows/sync.yml/badge.svg" alt="Sync status">
  </a>
  <a href="https://github.com/MohammadMD1383/node-headers/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
  </a>
  <img src="https://img.shields.io/github/v/tag/MohammadMD1383/node-headers?label=latest" alt="Latest tag">
  <img src="https://img.shields.io/badge/node-%3E%3D18-339933" alt="Node >= 18">
</div>

---

## ✨ Why?

Native Node.js addons (C/C++ modules) need the Node.js headers to compile. The standard approach — `node-gyp install` — downloads headers on every build, requires Python and a build toolchain, and pulls from the network every time.

**This repo is a better way:** it's a git mirror of official Node.js headers, one tag per version. Consume it with a `git submodule` and your build system just needs the headers on disk — no network fetch, no extra tooling, no CI surprises.

## 🚀 Quick start

```bash
# Add as a submodule
git submodule add https://github.com/MohammadMD1383/node-headers.git deps/node-headers

# Pin to a specific Node.js version (shallow — one version only)
cd deps/node-headers
git fetch --depth 1 origin v22.5.1
git checkout v22.5.1
cd ../..

# Keep it shallow for future updates
git config -f .gitmodules submodule.deps/node-headers.shallow true

# Commit the pin
git add .gitmodules deps/node-headers
git commit -m "Pin Node headers to v22.5.1"
```

Then in your `binding.gyp`, `CMakeLists.txt`, or equivalent:
```makefile
include_dirs: ["deps/node-headers/include/node"]
```

**Bumping to a newer Node version later:**

```bash
cd deps/node-headers
git fetch --depth 1 origin v23.4.0
git checkout v23.4.0
cd ../..
git add deps/node-headers
git commit -m "Bump Node headers to v23.4.0"
```

## 🔄 How it works

- Every 6 hours, [a GitHub Actions workflow](.github/workflows/sync.yml) checks `https://nodejs.org/dist/index.json` for new releases.
- For each new version, it downloads the headers tarball (`.tar.xz` when available — ~100 KB instead of ~10 MB), commits it as an **orphan commit**, and tags it `vX.Y.Z`.
- **Orphan commits** mean each tag is an independent snapshot. A shallow fetch of a single tag downloads only that version's headers — not the entire repo's history.

## 📋 Which versions are included?

**All released versions from Node 18 onward** (v18.0.0 → present), including both LTS and non-LTS (odd majors). This repo currently mirrors **199 versions** and grows with every new Node.js release.

Adjust the floor by setting `MIN_MAJOR` — see [sync.sh](scripts/sync.sh).

## 🌟 Benefits

| Approach | Network | Tooling | Setup time |
|---|---|---|---|
| **node-gyp install** | Every build | Requires Python + toolchain | ~30s per build |
| **npm `@node-rs/headers`** | Per install | Requires npm | ~10s per install |
| **This repo** | Once per version | None (just git) | Instant |

- ✅ **No Python required** — git + your C/C++ compiler is all you need
- ✅ **Offline builds** — once fetched, headers are on disk
- ✅ **CI-friendly** — `git fetch --depth 1` is fast and reliable
- ✅ **Transparent** — plain files, no abstraction layer
- ✅ **Air-gap friendly** — mirror the repo once, clone from your internal network

## ⚙️ One-time setup (for your fork)

If you want to run your own mirror:

1. Create an empty repo on GitHub.
2. Copy in `scripts/sync.sh`, `.github/workflows/sync.yml`, and this `README.md`.
3. **Enable Actions write permissions** — go to **Settings → Actions → General → Workflow permissions → "Read and write permissions"**.
4. Seed historical versions:
   ```bash
   MIN_MAJOR=18 bash scripts/bootstrap.sh
   ```
5. That's it — the cron job handles everything from there.

## 📘 License

The code in this repo (sync scripts, workflows, documentation) is MIT licensed.
The Node.js headers themselves are copyright of the Node.js contributors and are distributed under the [Node.js license](https://raw.githubusercontent.com/nodejs/node/main/LICENSE) (MIT).

---

<p align="center">
  <sub>Built with ❤️ for the native addon community · Maintained automatically via GitHub Actions</sub>
</p>
