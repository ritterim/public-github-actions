# npm-config-npmjs-org-registry

A composite action which will configure NPM to use the NPM (npmjs.org) package registry.

This uses `npm config set` commands to set the API key and scope registry for the specified scope.  This updates the user profile's `.npmrc` file with the API key needed to talk to the registry.

- [npm-config-npmjs-org-registry](#npm-config-npmjs-org-registry)
- [Example](#example)

# Example

```
      - name: npm-config-npmjs-org-registry
        uses: ritterim/public-github-actions/actions/npm-config-npmjs-org-registry@v1.9.0
        with:
          npmjs_api_key: ${{ secrets.npmjs_api_key }}
```
