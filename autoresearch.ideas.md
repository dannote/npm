# Autoresearch Ideas

## Implemented
- ~~Nested linker, PeerDeps, Dedupe, Workspace, Outdated, Audit, Why, Diff, Fund, License~~
- ~~Prune, Pack, Shrinkwrap, DepCheck, Deprecation, Tree, Search, Stats, Overrides, Verify~~
- ~~Scripts, Token, Publish, Size, BinResolver tests, Compiler tests~~
- ~~Split monolith test file, ex_dna quality gate, fixed code clones~~
- ~~Init, Link, CI, Doctor, Completion, Resolutions, Import, EngineCheck~~
- ~~BundleDeps, OptionalDeps, DevDeps, Exports extensions, Exec, Rebuild~~
- ~~Config extensions, PeerDepsCheck, Normalize, TypesResolution, Changelog~~
- ~~Duplicate, Ignore, GitInfo~~
- ~~Refactored Workspace.topo_sort and DepGraph.cycles to use :digraph_utils~~

## Medium Priority: New Modules
- `NPM.Provenance` — SLSA provenance / supply chain attestation checking
- `NPM.SBOM` — Software Bill of Materials generation (CycloneDX/SPDX)
- `NPM.Cve` — CVE database cross-referencing
- `NPM.FileSize` — individual file size analysis within packages
- `NPM.VersionRange` — advanced version range manipulation (intersect, union, complement)

## Medium Priority: More Tests
- Error handling paths in Registry, Tarball, Cache
- Edge cases in Resolver, Linker, LockMerge
- More tests for existing mix tasks
- Lockfile round-trip (write then read) edge cases
- PackageSpec complex range parsing edge cases

## Lower Priority: Enhance Existing
- Workspace module: workspace:* protocol range support
- CI module: clean_and_install! action
- Link module: global link registry
