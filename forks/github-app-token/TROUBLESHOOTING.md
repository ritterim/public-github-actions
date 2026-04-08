# Troubleshooting

## `ncc build` segfaults (Segmentation fault: 11)

### Symptom

Running `npm run build` fails with a segfault:

```
sh: line 1: <pid> Segmentation fault: 11  ncc build src/index.ts --minify --v8-cache
```

### Root cause

`@vercel/ncc` stores V8 bytecode cache files alongside its own bundled scripts:

- `node_modules/@vercel/ncc/dist/ncc/cli.js.cache`
- `node_modules/@vercel/ncc/dist/ncc/index.js.cache`
- `node_modules/@vercel/ncc/dist/ncc/sourcemap-register.js.cache`

These bytecode caches are Node.js version-specific. If the active Node.js version changes (e.g. via nvm, fnm, or a system upgrade) after these files were last written, Node will attempt to load incompatible bytecode and segfault.

### Solution

Reinstall `@vercel/ncc` to replace the stale cache files:

```sh
npm uninstall @vercel/ncc && npm install --save-dev @vercel/ncc
```

> Note: simply deleting the `.cache` files does not work — ncc requires them to exist at startup and will error if they are missing. Empty files also cause a segfault because Node rejects a zero-length bytecode buffer. The reinstall is the cleanest fix.
