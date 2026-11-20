#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Wampeter Foma
#
# dist.sh: build the cursor themes and pack them into a release archive.
#
# Usage:
#   ./dist.sh
#
# What it does:
#   - runs ./build.sh
#   - packs the built themes, install.sh, README and both licences
#   - all under one top-level folder, xfce4-beacon-cursor-theme/
#
# Needs:
#   - the build tools (build.sh checks them)
#   - tar, gzip
#
# Writes:
#   - dist/xfce4-beacon-cursor-theme.tar.gz
set -eu

NAME=xfce4-beacon-cursor-theme

missing=""
for c in tar gzip; do
	command -v "$c" >/dev/null || missing="$missing $c"
done
[ -z "$missing" ] || {
	echo "dist.sh: missing tools:$missing" >&2
	exit 1
}

cd "$(dirname "$0")"

./build.sh

rm -rf dist
mkdir -p "dist/$NAME"
cp -a build install.sh README.md LICENSE LICENSE-ART "dist/$NAME/"
# root ownership in the archive: never the packer's user name
tar --owner=0 --group=0 --numeric-owner -czf "dist/$NAME.tar.gz" -C dist "$NAME"
rm -r "dist/$NAME"
echo "packed dist/$NAME.tar.gz"
