# Autoresearch Ideas

## Medium Priority: Real Features
- `npm ci --frozen-lockfile` strict mode (reject if lockfile is out of sync with package.json)
- `npm ls --json` output format for tooling integration
- `npm why` trace through nested deps to explain why a package is installed
- Pre/post install script execution (lifecycle hooks — currently only detection)
- `npm pack` integration with tarball creation from local project
- Progress bar / streaming output during multi-package downloads

## Lower Priority: Polish
- `npm audit` with real advisory API integration
- `npm diff` between installed and registry versions
- `npm fund` with real funding URL display
- bundleDependencies handling in tarballs
- `npm shrinkwrap` lockfile freezing
- `npm token` management for auth tokens
