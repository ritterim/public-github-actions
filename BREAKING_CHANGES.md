# Breaking Changes

## 1.3.0 (Sep 2023)

- The NPM publish workflows will now require `artifact_file_path` to be passed in instead of assuming that the filename to publish is the `artifact_name` plus a `.tgz` suffix.

## 1.2.0 (Aug 30, 2023)

- The NPM workflow/actions `package_lock_filename` and `package_filename` inputs have changed names to `package_json_filename` for clarity.
