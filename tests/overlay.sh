#!/bin/sh
# -*- Mode: sh; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2015 Canonical, Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -ex

ROOT=$(mktemp -d "$BUILDDIR/snappy-preload.test.XXXXXXXXXX")
UNDERLAY="$ROOT/underlay"
OVERLAYROOT="$ROOT/overlay"
OVERLAY="$OVERLAYROOT$UNDERLAY"

export "SNAPPY_PRELOAD=$OVERLAYROOT"

mkdir -p "$UNDERLAY" "$OVERLAY"

echo "a" > "$UNDERLAY/in-both"
echo "not-in-over" > "$UNDERLAY/not-in-over"

echo "b" > "$OVERLAY/in-both"
echo "not-in-under" > "$OVERLAY/not-in-under"

# open
test "$(LD_PRELOAD=$PRELOAD cat $UNDERLAY/in-both)" = "b"
test "$(LD_PRELOAD=$PRELOAD cat $UNDERLAY/not-in-over)" = "not-in-over"
test "$(LD_PRELOAD=$PRELOAD cat $UNDERLAY/not-in-under)" = "not-in-under"

# opendir
test "$(LD_PRELOAD=$PRELOAD ls -1 $UNDERLAY | tr '\n' ' ')" = "in-both not-in-under "

# unlink
LD_PRELOAD=$PRELOAD rm $UNDERLAY/in-both
test "$(LD_PRELOAD=$PRELOAD cat $UNDERLAY/in-both)" = "a"
echo "b" > "$OVERLAY/in-both"

# chmod
chmod 400 "$OVERLAY/in-both"
chmod 600 "$UNDERLAY/in-both" # just for comparison
WRITE_OUTPUT=$(LD_PRELOAD=$PRELOAD sh -c "echo c > $UNDERLAY/in-both" || echo failed)
test "$WRITE_OUTPUT" = "failed"

# stat
test "$(stat --printf=%a $UNDERLAY/in-both)" = "600"
test "$(LD_PRELOAD=$PRELOAD stat --printf=%a $UNDERLAY/in-both)" = "400"
