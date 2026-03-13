# Autoresearch Ideas

## Done: Two-Phase Resolver (express works!)
- ✅ Detects version conflicts in PubGrub error messages
- ✅ Excludes conflicting package, retries with nesting
- ✅ express@4.x now resolves (69 packages + ms as nested)
- Still TODO: Linker needs to create nested node_modules for excluded packages
  - debug/node_modules/ms@2.0.0 and send/node_modules/ms@2.1.3
  - Need to track WHICH version each parent needs
  - Currently the excluded packages just aren't installed at all

## Next: Nested Linker
- Modify Linker to read the :nested key from resolved map
- For each excluded package, find which parents need which version
- Create parent_pkg/node_modules/excluded_pkg/ directories
- This requires the lockfile to track nested entries too

## Other Real Compatibility Gaps
- `npm ls` should show nested packages in tree output
- `npm ci` should handle nested lockfile entries
- `npm why` should trace through nested deps
- Pre-release ranges (e.g., `1.0.0-alpha || ^1.0.0`)

## Lower Priority
- mix npm.publish, mix npm.import already partially implemented
- Progress bar during download
- bundleDependencies handling in tarballs
