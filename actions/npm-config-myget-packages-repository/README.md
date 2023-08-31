# npm-config-myget-packages-repository

A composite action which will configure NPM to use the MyGet NPM package registry.

This uses `npm config set` commands to set the API key and scope registry for the specified scope.  This updates the user profile's `.npmrc` file with the API key needed to talk to the MyGet NPM package registry.

WARN: It's not designed for use outside of our organization due to the hardcoded URLs.

- [npm-config-myget-packages-repository](#npm-config-myget-packages-repository)
- [Example](#example)

# Example

```
      - name: npm-config-myget-packages-repository
        uses: ritterim/public-github-actions/actions/npm-config-myget-packages-repository@v1.2.0
        with:
          myget_api_key: ${{ secrets.myget_api_key }}
```
