# Autoresearch Ideas

## Implemented
- ~~Nested linker~~ (two-phase resolver, nested version conflicts)
- ~~PeerDeps module~~ (extract, check, format_warnings, optional peers)
- ~~Dedupe module~~ (find_duplicates, best_shared_version, savings_estimate)
- ~~Workspace module~~ (discover, dep_graph, build_order, topo sort)
- ~~Split monolith test file into per-module files~~

## Medium Priority: Real Features
- `npm ci --frozen-lockfile` strict mode — verify lockfile-to-package.json sync more thoroughly
- `npm why` trace through nested deps to explain why a package is installed
- Pre/post install script execution (lifecycle hooks — currently only detection)
- `npm pack` integration with tarball creation from local project
- `NPM.Audit` — security advisory checking against known vulnerability databases
- `NPM.Outdated` — compare installed versions against latest available

## Lower Priority: Polish
- `npm diff` between installed and registry versions
- `npm fund` with real funding URL display
- bundleDependencies handling in tarballs
- `npm shrinkwrap` lockfile freezing
- Progress bar / streaming output during multi-package downloads
