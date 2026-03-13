# Autoresearch Ideas

## Implemented (91 lib modules, 98 test files, 2000 tests)

## New Modules
- `NPM.Validate` — package.json schema validation (required fields, types, known fields, warn unknown)
- `NPM.Engines` — engine field parsing/matching (node, npm, yarn version constraints)
- `NPM.Funding` — funding field parsing (url, type, multiple funders)
- `NPM.DepRange` — dependency range analysis (how many pinned, floated, star, url deps)
- `NPM.InstallStrategy` — hoisted vs nested vs isolated install strategies
- `NPM.NodeVersion` — .nvmrc/.node-version/.tool-versions parsing
- `NPM.Overrides` extensions — flatten, apply, validate override specs
- `NPM.Alias` extensions — resolve npm:pkg@ver aliases, detect cycles

## More Tests for Existing Modules
- Registry error handling paths (network failures, invalid JSON, 404)
- Tarball error paths (corrupt archive, integrity mismatch)
- Resolver edge cases (circular deps, conflicting ranges)
- LockMerge edge cases (conflicting merges, missing entries)
- PackageSpec complex ranges (pre-release, build metadata, tags)
- Mix task tests (argument parsing, output format)
- Compiler edge cases (missing package.json, invalid JSON)
- FrozenInstall additional validation scenarios

## Enhance Existing
- Workspace: workspace:* protocol range support
- CI: clean_and_install! action
- Link: global link registry
- Exec: auto-install missing binaries
