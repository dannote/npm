# Autoresearch Ideas

## Implemented
- ~~60+ modules, 80+ test files, 1800 tests~~
- ~~All medium priority modules done (Provenance, SBOM, Cve, FileSize, VersionRange, etc.)~~
- ~~:digraph_utils refactor, ex_dna gate, edge case sweeps~~

## New Modules
- `NPM.Validate` — comprehensive package.json schema validation (required fields, types, known field checks)
- `NPM.Scope` — scope management (parse @scope/name, extract scope, validate scope names)
- `NPM.Dist` — dist metadata (tarball URLs, shasum, file count, unpacked size)
- `NPM.Os` — os/cpu field checking (platform compatibility matrix)
- `NPM.Hooks` edge cases — pre/post lifecycle hooks ordering and filtering
- `NPM.Monorepo` — detect monorepo type (npm workspaces, lerna, turborepo, nx)

## More Tests for Existing Modules
- Registry error handling paths (network failures, invalid JSON, 404)
- Tarball error paths (corrupt archive, integrity mismatch)
- Cache error paths (disk full, permission denied)
- Resolver edge cases (circular deps, conflicting ranges)
- LockMerge edge cases (conflicting merges, missing entries)
- PackageSpec complex ranges (pre-release, build metadata, tags)
- Mix task tests (argument parsing, output format)

## Enhance Existing
- Workspace: workspace:* protocol range support
- CI: clean_and_install! action
- Link: global link registry
- Exec: auto-install missing binaries
