# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

How to release:
1. Rename `Unreleased` below to the new version and date, e.g. `## [1.0.0] - 2026-11-20`.
2. Add a new, empty `Unreleased` section above it.
3. Commit, then tag the commit `v<version>` (e.g. `v1.0.0`) and push the tag.
4. CI builds the archive and creates the release, with that version's section as
   its notes.

## [Unreleased]

### Added

- Four high-visibility cursor themes: yellow, lime, cyan and magenta.
- Every cursor name Adwaita ships, the DMZ-White legacy X11 set, and extra
  aliases (`dnd-*`, `size_all`).
- Sizes 32 to 128 px; animated `wait` and `progress`.
- `build.sh`, `install.sh`, and a container build (`Dockerfile`).
- `previews.sh` to regenerate the screenshots, and `test.sh` to check every
  cursor name.
- `dist.sh` and CI to build release archives.
