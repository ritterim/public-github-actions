# GitHub App Token

The current code is based on [v1.8.0](https://github.com/tibdex/github-app-token/tree/releases/v1.8.0) of `tibdex/github-app-token`.  Additions have been made in order to make debugging of GitHub workflows easier when using this action.

- [GitHub App Token](#github-app-token)
- [Notes](#notes)
- [Example Workflow](#example-workflow)
- [References](#references)

# Notes

This [JavaScript GitHub Action](https://help.github.com/en/actions/building-actions/about-actions#javascript-actions) can be used to impersonate a GitHub App when `secrets.GITHUB_TOKEN`'s limitations are too restrictive and a personal access token is not suitable.

For instance, from [GitHub Actions' docs](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow):

> When you use the repository's `GITHUB_TOKEN` to perform tasks, events triggered by the `GITHUB_TOKEN`, with the exception of `workflow_dispatch` and `repository_dispatch`, will not create a new workflow run.
> This prevents you from accidentally creating recursive workflow runs.
> For example, if a workflow run pushes code using the repository's `GITHUB_TOKEN`, a new workflow will not run even when the repository contains a workflow configured to run when push events occur.

A workaround is to use a [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) from a [personal user/bot account](https://help.github.com/en/github/getting-started-with-github/types-of-github-accounts#personal-user-accounts).
However, for organizations, GitHub Apps are [a more appropriate automation solution](https://developer.github.com/apps/differences-between-apps/#machine-vs-bot-accounts).

# Example Workflow

```yml
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - name: Generate token
        id: generate_token
        uses: ritterim/public-github-actions/forks/github-app-token@v1.17
        with:
          app_id: ${{ secrets.APP_ID }}

          # Optional.
          # github_api_url: https://api.example.com

          # Optional.
          # installation_id: 1337

          # Optional.
          # Using a YAML multiline string to avoid escaping the JSON quotes.
          # permissions: >-
          #   {"members": "read"}

          private_key: ${{ secrets.PRIVATE_KEY }}

          # Optional.
          # repository: owner/repo

      - name: Use token
        env:
          TOKEN: ${{ steps.generate_token.outputs.token }}
        run: |
          echo "The generated token is masked: ${TOKEN}"
```

# References

- [tibdex/github-app-token](https://github.com/tibdex/github-app-token) -- MIT license
- [jnwng/github-app-installation-token-action](https://github.com/jnwng/github-app-installation-token-action) -- MIT license
- [Create a JavaScript Action using TypeScript](https://github.com/actions/typescript-action)
