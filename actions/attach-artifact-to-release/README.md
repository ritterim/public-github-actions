# attach-artifact-to-release

Attach artifact from the workflow run to a GitHub Release.

- [attach-artifact-to-release](#attach-artifact-to-release)
- [Example](#example)

# Example

```
      - name: Attach Artifact to GitHub Release
        uses: ritterim/public-github-actions/attach-artifact-to-release@v1.3.0
        with:
          artifact_name: ${{ inputs.artifact_name }}
          artifact_file_path: ${{ inputs.artifact_file_path }}
          github_repository: ${{ github.repository }}
          github_token: ${{ github.token }}
          version_tag: ${{ env.GH_REF_NAME }}
```
