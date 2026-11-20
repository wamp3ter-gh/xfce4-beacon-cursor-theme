#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Wampeter Foma
#
# test.sh: check every built theme has all its cursor names.
#
# Usage:
#   ./test.sh
#   ./test.sh <dir>
#
# Arguments:
#   - none: build in a clean container first, into a fresh build.test/
#   - dir: check the themes already built in <dir> (CI uses build/), no Docker
#
# What it does:
#   - checks each theme has every cursor and alias the SHAPES table in build.sh lists
#   - without <dir>, leaves build/ alone
#
# Needs:
#   - Docker, only without <dir>
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

if [ $# -eq 0 ]; then
	OUT=$ROOT/build.test
	command -v docker >/dev/null || {
		echo "test.sh: missing tool: docker" >&2
		exit 1
	}
	# docker build adds to an existing folder, so start from an empty one
	rm -rf "$OUT"
	docker build -o "$OUT" "$ROOT"
elif [ $# -eq 1 ]; then
	OUT=$1
	[ -d "$OUT" ] || {
		echo "test.sh: no folder $OUT" >&2
		exit 1
	}
else
	echo "test.sh: usage: ./test.sh [dir]" >&2
	exit 1
fi

# every name in SHAPES: the cursor (column 1) and its aliases (column 7 onwards)
names=$(awk '/^SHAPES="/ {on = 1; next} on && /^"/ {exit} on && NF {for (i = 1; i <= NF; i++) if (i == 1 || i >= 7) print $i}' "$ROOT/build.sh")
[ -n "$names" ] || {
	echo "test.sh: found no SHAPES table in build.sh" >&2
	exit 1
}

fail=0 themes=0
for d in "$OUT"/*/; do
	[ -f "$d/index.theme" ] || continue
	themes=$((themes + 1))
	for n in $names; do
		if [ ! -e "$d/cursors/$n" ]; then
			echo "missing: $(basename "$d")/cursors/$n"
			fail=1
		fi
	done
done
[ "$themes" -gt 0 ] || {
	echo "test.sh: no themes in $OUT" >&2
	exit 1
}
count=$(echo "$names" | wc -l)
[ "$fail" = 0 ] || exit 1
echo "test.sh: $themes themes, each with all $count cursor names"
