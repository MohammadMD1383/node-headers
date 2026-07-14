# Contributing

Thanks for wanting to help make `node-headers` better!

## How this repo works

This repo is a **fully automated mirror** — the `sync.sh` script runs on a cron
schedule via GitHub Actions and doesn't normally need human intervention. Most
"contributions" are just filing issues when something breaks.

## What's helpful

- **Report missing tags** — if a new Node.js version was released more than
  6 hours ago and hasn't appeared here, [open an issue](../../issues/new).
- **Report broken tags** — if a tag is missing files or has corrupt headers,
  let us know.
- **Improve the docs** — typos, confusing explanations, missing use cases.
  PRs for README improvements are always welcome.
- **Script improvements** — if `sync.sh` or `bootstrap.sh` can be faster,
  more reliable, or handle edge cases better, open a PR.

## Before you open a PR

1. Make sure the existing tests/verify steps pass.
2. If you're changing `sync.sh`, test with `DRY_RUN=true` first.
3. Update the README if your change affects how people use the repo.

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](LICENSE).
