# Autoresearch Ideas

## Completed (v0.4.0) — 30 tasks, 12 lib modules, 250 tests
- devDependencies, optionalDependencies, overrides, workspaces
- bin linking (string/map/directories.bin), pruning, --save-exact/--save-dev/--save-optional/--production
- Custom registry, auth tokens, retry, .npmrc, SHA-256, peerDeps/deprecation warnings
- Lockfile diff, NPM.Validator, NPM.Compiler, NPM.Config, file:/git: dep detection
- 30 Mix tasks: init install get remove list ls update outdated tree why info search run exec ci check clean cache config version link diff pack audit dedupe prune fund rebuild uninstall

## High-Value Pending Features
- **Lifecycle scripts** — run `preinstall`, `install`, `postinstall` scripts from packages (common npm feature, needs careful sandboxing)
- **`exports` field parsing** — modern Node.js conditional exports resolution (package.json `exports` map)
- **`type: "module"` detection** — detect ESM vs CJS and expose in package info
- **`engines` field warnings** — warn when resolved pkg requires incompatible Node version
- **Lockfile v2 with checksums** — add integrity checksums inline in lockfile for faster verification
- **`resolutions` field** — Yarn-style forced version overrides (different from `overrides`)
- **`mix npm.publish`** — publish to npm registry with token auth
- **Progress output** — show download progress during install
- **Nested node_modules** — create nested `node_modules` when version conflicts exist (proper npm algorithm)
- **`peerDependenciesMeta` support** — mark peer deps as optional
- **`bundleDependencies` support** — handle bundled deps in tarballs
- **`os`/`cpu` field filtering** — skip packages incompatible with current platform
