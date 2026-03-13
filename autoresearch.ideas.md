# Autoresearch Ideas

## Critical Bug: Flat Resolution Cannot Handle Version Conflicts
- **express@4.x fails to resolve** because `debug@2.6.9` needs `ms@2.0.0` and `send@0.19.0` needs `ms@2.1.3`
- npm handles this via nested `node_modules` (multiple versions of same package)
- PubGrub solver assumes one version per package (flat)
- **Root cause**: exact version pin conflicts (ms@2.0.0 vs ms@2.1.3) in transitive deps
- **Fix approach**: Two-phase resolution
  1. Run PubGrub first. If it succeeds, done (flat layout works).
  2. On conflict, identify the conflicting package (e.g. `ms`). Pick latest version for top-level, remove the conflicting exact pins from the solver and re-solve. Track nested versions separately.
  3. Linker creates `debug/node_modules/ms/` for the older pinned version.
- This is the single most impactful fix for real-world npm compatibility.

## Real npm Compatibility Gaps Found by Integration Tests
- `*`, `""`, `latest` ranges now fixed (normalize to `>=0.0.0`)
- Need to test: `x.x.x`, `1.x`, `1.2.x` range syntax via resolver (currently handled by npm_semver dep)
- Need to test: pre-release version handling (`1.0.0-alpha.1`)
- Need to test: `||` union ranges through the full resolver

## High-Value Pending Features
- **Nested node_modules** — CRITICAL for real npm compat (blocks express, many real packages)
- **`mix npm.publish`** — pack + upload tarball to registry
- **Lockfile v2 format** — add checksums inline
- **Progress bar** — show download progress
- **`bundleDependencies` support** — handle bundled deps in tarballs

## Lower Priority
- NPM.RegistryMirror, NPM.LockMerge, mix npm.import already partially implemented but uncommitted
- mix npm.size, mix npm.stats, mix npm.verify already added
