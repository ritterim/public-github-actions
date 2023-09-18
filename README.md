# public-github-actions

A repository to contain RIMdev's public GitHub Actions and reusuable workflow (YML) files.  Plus forks of other projects that we find useful and needed to version control for security/enhancements.

- [public-github-actions](#public-github-actions)
- [Versioning](#versioning)
  - [Release Process](#release-process)
- [Reusable Workflows](#reusable-workflows)
- [GitHub Actions](#github-actions)
  - [GitHub](#github)
  - [NPM Registry Configuration](#npm-registry-configuration)
  - [Validators](#validators)
- [Forked GitHub Actions](#forked-github-actions)

# Versioning

Because this mono-repo contains multiple GitHub actions and reusable workflow files, SemVer rules will be difficult to apply meaningfully or consistently.  See the [releases page](https://github.com/ritterim/public-github-actions/releases) for a list of current versions and the change logs.

- The major (1st) position will probably never change.
- The minor (2nd) position will bump frequently as we add new actions/workflows, remove old code or make a breaking change.
- The patch (3rd) position will bump for bug fixes.

Breaking changes will be mentioned in the [BREAKING_CHANGES.md](BREAKING_CHANGES.md) file.  Breaking changes should be rare, but there are no guarantees.

You can use the 'git' command line to look at changes for a specific path / file.

    git diff refs/tags/v1.0.0 refs/tags/v1.1.1 -- .github/workflows/

## Release Process

Summary: Version tags which have [release notes published](https://github.com/ritterim/public-github-actions/releases) should be safe to use.  For upcoming releases, we recommend avoiding them until a release has been published.

1. A new annotated tag will be pushed up to the repo.  This tag will have 'DRAFT' somewhere in the comment.

2. The reusable workflows and actions will be updated to point at this new version tag.

3. Changes are tested.

4. The annotated tag is deleted, then recreated with a comment of "Release x.y.z".

5. A GitHub Release is created from the annotated tag.

# Reusable Workflows

Reusable GitHub Actions workflows. See [ReusableWorkflows.md](ReusableWorkflows.md) for the list and documentation.

# GitHub Actions

GitHub Actions authored by RIMdev.

## GitHub

- [attach-artifact-to-release](actions/attach-artifact-to-release/)
- [calculate-version-from-txt-using-github-run-id](actions/calculate-version-from-txt-using-github-run-id/)
- [create-github-release](actions/create-github-release/)

## NPM Registry Configuration

These actions help configure your `.npmrc` file to authenticate against different NPM registries for retrieving and/or publishing NPM packages.

- [npm-config-github-packages-repository](actions/npm-config-github-packages-repository/)
- [npm-config-myget-packages-repository](actions/npm-config-myget-packages-repository/)
- [npm-config-npmjs-org-registry](actions/npm-config-npmjs-org-registry)

## Validators

Actions which can be used to validate input values to workflows against RegEx patterns.  While not guaranteed, these can help reduce the risk of command-line injection vulnerabilities or guard against simple mistakes.

- [file-name-validator](actions/file-name-validator/)
- [github-org-repository-validator](actions/github-org-repository-validator/)
- [github-token-validator](actions/github-token-validator/)
- [npm-package-name-validator](actions/npm-package-name-validator/)
- [npm-package-scope-validator](actions/npm-package-scope-validator/)
- [npmjs-access-token-validator](actions/npmjs-access-token-validator/)
- [path-name-validator](actions/path-name-validator/)
- [regex-validator](actions/regex-validator/)
- [version-number-validator](actions/version-number-validator/)

# Forked GitHub Actions

GitHub Actions which have been "vendored" for use by RIMdev.  These will stray away from the upstream version as needed.

- [github-app-token](forks/github-app-token/)
- [persist-workspace](forks/persist-workspace/)

