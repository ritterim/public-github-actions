# Repo instructions for Claude

## Keep .github/dependabot.yml in sync

The `github-actions` ecosystem in Dependabot only scans the exact directory you give it — it does not recurse into subdirectories. Because of that, `.github/dependabot.yml` has one `github-actions` entry per action directory (every `actions/*/action.yml` and `forks/*/action.yml`), plus one entry for the root `.github/workflows` tree and one for `forks/persist-workspace/.github/workflows`.

Whenever a new action is added under `actions/` or `forks/`, or a new fork brings its own `.github/workflows` tree, add a matching `github-actions` entry to `.github/dependabot.yml` in the same PR. Whenever an action or fork directory is removed, remove its entry too.

Whenever a new `package-lock.json` is added under `actions/*` or `forks/*`, add its path to the `directories:` list on the existing `npm` entry in `.github/dependabot.yml` rather than creating a new entry.
