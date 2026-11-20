#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-only
# SPDX-FileCopyrightText: 2026 Wampeter Foma
# Render src/*.svg for every theme at every size and pack each into an Xcursor file.
# Output: build/<theme>/ (index.theme + cursors/). KEEP_PNG=1 keeps the rendered frames in
# build/tmp/<theme>-<shape>-<frame>-<size>.png (previews.sh reads them).
set -eu

# every tool this script runs, checked up front so a missing one can't stop a half-done build
missing=""
for c in rsvg-convert xcursorgen awk sed; do
	command -v "$c" >/dev/null || missing="$missing $c"
done
[ -z "$missing" ] || {
	echo "build.sh: missing tools:$missing (install them, see README Requirements, or build with docker: see README)" >&2
	exit 1
}

# CDPATH= stops cd printing a directory into $(...) when CDPATH is set
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# run only from inside the repo: through a symlink elsewhere, ROOT would point at
# another folder, and build/ there would be replaced
[ -d "$ROOT/src" ] && [ -f "$ROOT/index.theme" ] || {
	echo "build.sh: $ROOT is not the cursor theme repo (no src/ or index.theme); run the script from its own folder" >&2
	exit 1
}
SIZES="32 40 48 56 64 72 96 128"
# render into build.new and swap it in only when every theme built, so a failed
# build never destroys the previous one
NEW=$ROOT/build.new
TMP=$NEW/tmp
OUTER="#000000" # outermost ring, every theme

# Border widths in 32-unit viewBox units (1 unit = 1.5 px at size 48).
# Sources write stroke widths as {O}, {I}, {w+O}, {w+I}; strokes are centred on the edge,
# so O = 2*(in+out) puts the outer ring BORDER_IN+BORDER_OUT outside the fill.
BORDER_IN=${BORDER_IN:-0.5}
BORDER_OUT=${BORDER_OUT:-0.5}
O=$(awk -v i="$BORDER_IN" -v o="$BORDER_OUT" 'BEGIN { print 2 * (i + o) }')
I=$(awk -v i="$BORDER_IN" 'BEGIN { print 2 * i }')

# Replace each {w+O}, {w+I}, {O}, {I} with its number.
widths() {
	awk -v O="$O" -v I="$I" '{
		while (match($0, /\{[0-9.]*\+?[OI]\}/)) {
			e = substr($0, RSTART + 1, RLENGTH - 2)
			k = substr(e, length(e), 1)
			n = (length(e) > 1) ? substr(e, 1, length(e) - 2) + 0 : 0
			$0 = substr($0, 1, RSTART - 1) (n + (k == "O" ? O : I)) substr($0, RSTART + RLENGTH)
		}
		print
	}'
}

# theme  arrow/hand fill + inner ring  text fill + inner ring
# Light fills get a black inner ring (one black border); dark fills a white one (white + black).
THEMES="
beacon-yellow  #ffe600 #000000  #ffe600 #000000
beacon-lime    #c0ff00 #000000  #c0ff00 #000000
beacon-cyan    #00e5ff #000000  #00e5ff #000000
beacon-magenta #ff00ff #ffffff  #ff00ff #ffffff
"

FRAME_MS=80 # per frame of an animated shape

# shape  source-svg  rotation  frames  hotspot-x hotspot-y (32-unit viewBox)  aliases
# Animated sources turn @SPIN@ through 360 degrees over their frames.
# Aliases follow Adwaita's own links (ls -l /usr/share/icons/Adwaita/cursors), plus
# size_all: Qt's xcb plugin asks only that name for its move cursor (qxcbcursor.cpp
# cursorNames), and Adwaita lacks it, so Qt would fall back to the core X cursor.
# The legacy X names Adwaita lacks (tees, angles, sb_ arrows, right_ptr, dotbox, pencil,
# color-picker) are drawn where DMZ-White draws them, and aliased where DMZ aliases them
# (ls -l /usr/share/icons/DMZ-White/cursors).
# One-way resize arrows click just inside the arrowhead (tip + 1.5 units), so the
# click lands where the eye aims; two-way arrows click at the centre, as in Adwaita.
SHAPES="
default       default      0   1  4  3 left_ptr arrow top_left_arrow move dnd-move
text          text         0   1 16 16 xterm ibeam
vertical-text text         90  1 16 16
pointer       pointer      0   1 12  4 hand2 hand pointing_hand
help          help         0   1  4  3 question_arrow left_ptr_help
context-menu  context-menu 0   1  4  3 dnd-ask
copy          copy         0   1 16 16 dnd-copy
alias         alias        0   1 16 16 dnd-link link
no-drop       no-drop      0   1  4  3 dnd-no-drop circle
progress      progress     0  12  4  3 left_ptr_watch half-busy
wait          wait         0  12 16 16 watch
not-allowed   not-allowed  0   1 16 16 crossed_circle
crosshair     crosshair    0   1 16 16 cross tcross cross_reverse diamond_cross
cell          cell         0   1 16 16 plus
X_cursor      x-cursor     0   1 16 16 pirate
grab          grab         0   1 16 20 hand1
grabbing      grabbing     0   1 16 19 dnd-none
all-resize    four-arrow   0   1 16 16 fleur size_all
all-scroll    four-arrow   0   1 16 16
zoom-in       zoom-in      0   1 13 13
zoom-out      zoom-out     0   1 13 13
ew-resize     double-arrow 0   1 16 16 sb_h_double_arrow h_double_arrow
ns-resize     double-arrow 90  1 16 16 sb_v_double_arrow v_double_arrow double_arrow
nwse-resize   double-arrow 45  1 16 16 bd_double_arrow
nesw-resize   double-arrow 135 1 16 16 fd_double_arrow
col-resize    split-arrow  0   1 16 16
row-resize    split-arrow  90  1 16 16
n-resize      edge-arrow   0   1 16 12 top_side
e-resize      edge-arrow   90  1 20 16 right_side
s-resize      edge-arrow   180 1 16 20 bottom_side
w-resize      edge-arrow   270 1 12 16 left_side
nw-resize     corner-arrow 0   1 11 11 top_left_corner
ne-resize     corner-arrow 90  1 21 11 top_right_corner
se-resize     corner-arrow 180 1 21 21 bottom_right_corner
sw-resize     corner-arrow 270 1 11 21 bottom_left_corner
top_tee       tee          0   1 16  5
right_tee     tee          90  1 27 16
bottom_tee    tee          180 1 16 27
left_tee      tee          270 1  5 16
ul_angle      angle        0   1  6  6
ur_angle      angle        90  1 26  6
lr_angle      angle        180 1 26 26
ll_angle      angle        270 1  6 26
sb_up_arrow   sb-arrow     0   1 16  3 up_arrow
sb_right_arrow sb-arrow    90  1 29 16
sb_down_arrow sb-arrow     180 1 16 29
sb_left_arrow sb-arrow     270 1  3 16
right_ptr     right-ptr    0   1 28  3 draft_large draft_small
dotbox        dotbox       0   1 16 16 target icon draped_box dot_box_mask
pencil        pencil       0   1  7 25
color-picker  color-picker 0   1  7 25
"

build_theme() {
	theme=$1 pfill=$2 pinner=$3 tfill=$4 tinner=$5
	# names become folder names and sed replacements, colours sed replacements
	printf '%s\n' "$theme" | grep -Eq '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' || {
		echo "build.sh: theme name '$theme': use letters, digits, _ . and -, not starting with ." >&2
		exit 1
	}
	for c in "$pfill" "$pinner" "$tfill" "$tinner"; do
		printf '%s\n' "$c" | grep -Eq '^#[0-9a-fA-F]{6}$' || {
			echo "build.sh: theme $theme: colour '$c' is not #rrggbb" >&2
			exit 1
		}
	done
	out=$NEW/$theme
	mkdir -p "$out/cursors"
	sed "s/@NAME@/$theme/" "$ROOT/index.theme" >"$out/index.theme"

	echo "$SHAPES" | while read -r name src rot frames hx hy aliases; do
		[ -n "$name" ] || continue
		case $name in
		text | vertical-text) fill=$tfill inner=$tinner ;;
		*) fill=$pfill inner=$pinner ;;
		esac
		conf=$TMP/$theme-$name.conf
		: >"$conf"
		f=0
		while [ "$f" -lt "$frames" ]; do
			svg=$TMP/$theme-$name-$f.svg
			sed -e "s/@FILL@/$fill/g" -e "s/@INNER@/$inner/g" -e "s/@OUTER@/$OUTER/g" \
				-e "s/@ROT@/$rot/g" -e "s/@SPIN@/$((f * 360 / frames))/g" \
				"$ROOT/src/$src.svg" | widths >"$svg"
			delay=""
			[ "$frames" -gt 1 ] && delay=" $FRAME_MS"
			for s in $SIZES; do
				png=$theme-$name-$f-$s.png
				rsvg-convert -w "$s" -h "$s" -o "$TMP/$png" "$svg"
				# scale the hotspot from 32 units to s pixels, rounded
				x=$(((hx * s + 16) / 32))
				y=$(((hy * s + 16) / 32))
				# relative name: xcursorgen reads the path only up to the first space,
				# and has no quoting, so a repo path with spaces would break it
				echo "$s $x $y $png$delay" >>"$conf"
			done
			f=$((f + 1))
		done
		(cd "$TMP" && xcursorgen "$conf" "$out/cursors/$name")
		for a in $aliases; do
			ln -s "$name" "$out/cursors/$a"
		done
	done
	echo "built build/$theme"
}

rm -rf "$NEW"
mkdir -p "$TMP"
echo "$THEMES" | while read -r theme pfill pinner tfill tinner; do
	[ -n "$theme" ] || continue
	build_theme "$theme" "$pfill" "$pinner" "$tfill" "$tinner"
done
[ -n "${KEEP_PNG:-}" ] || rm -rf "$TMP"
rm -rf "$ROOT/build"
mv "$NEW" "$ROOT/build"
