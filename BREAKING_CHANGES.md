# Breaking Changes

## 1.8.0 (Sep 2023)

- `dotnet-test.yml` no longer asks for the `secrets.mssql_password`.  Because this is a temporary database, not exposed to the world, and thrown away right after the workflow finishes -- we can just make up a password from the run values.

## 1.3.0 (Sep 2023)

- The NPM publish workflows will now require `artifact_file_path` to be passed in instead of assuming that the filename to publish is the `artifact_name` plus a `.tgz` suffix.
- The NPM publish workflows no longer take in `project_directory` as an input.

## 1.2.0 (Aug 30, 2023)

- The NPM workflow/actions `package_lock_filename` and `package_filename` inputs have changed names to `package_json_filename` for clarity.
