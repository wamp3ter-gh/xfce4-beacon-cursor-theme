#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Wampeter Foma
#
# previews.sh: the README images, rendered into screenshots/ from a fresh build.
#
# Usage:
#   ./previews.sh
#
# Needs:
#   - the build tools (build.sh checks them)
#   - ImageMagick: convert, montage
#   - find, sort
#
# Writes:
#   - screenshots/hero.png: key cursors of every theme on a dark and a light background
#   - screenshots/sheet-<theme>.png: every drawn cursor of one theme, named
#   - screenshots/sizes.png: one cursor at every built size
#   - screenshots/colour-vision.png: hero under simulated protanopia, deuteranopia, tritanopia
set -euo pipefail

# the extra tools for the images; build.sh checks its own
missing=()
for c in convert montage find sort; do command -v "$c" >/dev/null || missing+=("$c"); done
[ ${#missing[@]} -eq 0 ] || {
	echo "previews.sh: missing tools: ${missing[*]} (Debian/Ubuntu: imagemagick findutils coreutils)" >&2
	exit 1
}

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
OUT=$ROOT/screenshots
PNG=$ROOT/build/tmp
WORK=$ROOT/build/previews
DARK='#2b3d4a'
LIGHT='#e8e8e2'
INK='#f0f0e8'
KEY="default pointer text wait not-allowed grab nwse-resize crosshair"

KEEP_PNG=1 "$ROOT/build.sh"
rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
themes=$(find "$ROOT/build" -mindepth 1 -maxdepth 1 -name 'beacon-*' -printf '%f\n' | sort)

# hero: per theme, the key cursors on dark then on light
rows=()
for t in $themes; do
	for bg in "$DARK" "$LIGHT"; do
		files=()
		for n in $KEY; do files+=("$PNG/$t-$n-0-64.png"); done
		montage "${files[@]}" -tile 8x1 -geometry 64x64+10+10 -background "$bg" "$WORK/$t-${bg#\#}.png"
	done
	convert "$WORK/$t-${DARK#\#}.png" "$WORK/$t-${LIGHT#\#}.png" +append "$WORK/$t.png"
	rows+=(-label "$t" "$WORK/$t.png")
done
montage "${rows[@]}" -tile 1x -geometry +0+6 -pointsize 18 -background "$DARK" -fill "$INK" "$OUT/hero.png"

# sheet per theme: every drawn shape (frame 0 of animated ones), named
for t in $themes; do
	args=()
	# Take names from this theme's own cursors, not its aliases.
	# A theme whose name starts with another's (beacon-yellow, beacon-yellow-dark)
	# then gets only its own.
	for c in "$ROOT/build/$t/cursors"/*; do
		[ -L "$c" ] && continue
		n=${c##*/}
		args+=(-label "$n" "$PNG/$t-$n-0-64.png")
	done
	montage "${args[@]}" -tile 10x -geometry 64x64+16+10 -pointsize 12 -background "$DARK" -fill "$INK" "$OUT/sheet-$t.png"
done

# sizes: the default arrow at every built size, bottom-aligned
t=${themes%%$'\n'*}
args=()
for f in "$PNG/$t"-default-0-*.png; do
	s=${f##*-}
	s=${s%.png}
	args+=("$s:$f")
done
sorted=$(printf '%s\n' "${args[@]}" | sort -n)
tiles=()
for e in $sorted; do
	s=${e%%:*}
	convert "${e#*:}" -background "$DARK" -gravity south -extent 128x128 "$WORK/size-$s.png"
	tiles+=(-label "${s}px" "$WORK/size-$s.png")
done
montage "${tiles[@]}" -tile x1 -geometry +10+10 -pointsize 14 -background "$DARK" -fill "$INK" "$OUT/sizes.png"

# colour vision: Machado, Oliveira and Fernandes 2009 matrices, severity 1.0, linear RGB
declare -A MX=(
	[protanopia]="0.152286 1.052583 -0.204868 0.114503 0.786281 0.099216 -0.003882 -0.048116 1.051998"
	[deuteranopia]="0.367322 0.860646 -0.227968 0.280085 0.672501 0.047413 -0.011820 0.042940 0.968881"
	[tritanopia]="1.255528 -0.076749 -0.178779 -0.078411 0.930809 0.147602 0.004733 0.691367 0.303900"
)
cv=(-label "normal vision" "$OUT/hero.png")
for k in protanopia deuteranopia tritanopia; do
	convert "$OUT/hero.png" -colorspace RGB -color-matrix "${MX[$k]}" -colorspace sRGB "$WORK/cv-$k.png"
	cv+=(-label "$k (simulated)" "$WORK/cv-$k.png")
done
montage "${cv[@]}" -tile 2x -geometry +10+10 -pointsize 20 -background "$DARK" -fill "$INK" "$OUT/colour-vision.png"

rm -rf "$WORK" "$PNG"
ls "$OUT"
