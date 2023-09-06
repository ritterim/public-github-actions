# npm-config-github-packages-repository

A composite action which will configure NPM to use the GitHub Packages NPM registry.

This uses `npm config set` commands to set the GitHub token and scope registry for the specified scope.  This updates the user profile's `.npmrc` file with the GitHub token needed to talk to the GitHub Packages NPM registry.

- [npm-config-github-packages-repository](#npm-config-github-packages-repository)
- [GITHUB\_TOKEN Permissions](#github_token-permissions)
  - [Notes](#notes)
- [Example](#example)

# GITHUB_TOKEN Permissions

You must have requested `packages: read` (or `packages:write` to publish) in your workflow.  

## Notes 

- GitHub App tokens can not currently be used to access a GitHub Packages NPM registry.
 
- The NPM scope must match your GitHub organization name.  GitHub Packages will not let you push up NPM packages for another scope.

# Example

```
      - name: npm-config-github-packages-repository
        uses: ritterim/public-github-actions/actions/npm-config-github-packages-repository@v1.3.0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
