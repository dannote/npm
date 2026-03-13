# Autoresearch Ideas

## Critical Bug: Flat Resolution Cannot Handle Version Conflicts
- **express@4.x fails to resolve** because `debug@2.6.9` needs `ms@2.0.0` and `send@0.19.0` needs `ms@2.1.3`
- npm handles this via nested `node_modules` (multiple versions of same package)
- PubGrub solver assumes one version per package (flat)
- **Fix options**:
  1. Pre-process deps: when a package has exact version pins (like `ms@2.0.0`), exclude it from the flat solve and handle it separately via nested node_modules
  2. Implement a two-pass resolver: first solve ignoring exact pins, then nest conflicting exact versions
  3. Use npm's own algorithm instead of PubGrub

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
