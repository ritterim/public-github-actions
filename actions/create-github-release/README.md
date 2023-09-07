# create-github-release

A composite action which will create a GitHub Release using an existing tag in the GitHub repository.

- [create-github-release](#create-github-release)
- [Example](#example)

# Example

```
      - name: Create GitHub Release
        uses: ritterim/public-github-actions/create-github-release@v1.4.0
        with:
          github_repository: ${{ github.repository }}
          github_token: ${{ github.token }}
          release_title: ${{ github.event.head_commit.message }}
          version_tag: ${{ env.GH_REF_NAME }}
```
