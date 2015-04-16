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

echo "#!/bin/sh\nfalse" > "$UNDERLAY/in-both"
echo "#!/bin/sh\ntrue" > "$OVERLAY/in-both"
chmod a+x "$UNDERLAY/in-both"
chmod a+x "$OVERLAY/in-both"
LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/in-both"

echo "#!/bin/sh\ntrue" > "$UNDERLAY/only-in-under"
chmod a+x "$UNDERLAY/only-in-under"
LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/only-in-under"

echo "#!/bin/sh\ntrue" > "$OVERLAY/only-in-over"
chmod a+x "$OVERLAY/only-in-over"
LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/only-in-over"

cat <<EOF > "$OVERLAY/recurse1"
set -e
echo \$SNAPPY_PRELOAD
echo \$LD_PRELOAD
export LD_PRELOAD=xxx:\$LD_PRELOAD:xxx
count=\$1
count=\$((count-1))
if [ \$count -ge 0 ]; then
    \$0 \$count
fi
EOF
chmod a+x "$OVERLAY/recurse1"
RECURSE_OUTPUT=$(LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/recurse1 1" | tr '\n' ' ')
test "$RECURSE_OUTPUT" = "$SNAPPY_PRELOAD $PRELOAD $SNAPPY_PRELOAD xxx:$PRELOAD:xxx "

cat <<EOF > "$OVERLAY/recurse2"
set -e
echo \$SNAPPY_PRELOAD
echo \$LD_PRELOAD
unset SNAPPY_PRELOAD
unset LD_PRELOAD
count=\$1
count=\$((count-1))
if [ \$count -ge 0 ]; then
    \$0 \$count
fi
EOF
chmod a+x "$OVERLAY/recurse2"
RECURSE_OUTPUT=$(LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/recurse2 1" | tr '\n' ' ')
test "$RECURSE_OUTPUT" = "$SNAPPY_PRELOAD $PRELOAD $SNAPPY_PRELOAD $PRELOAD "

cat <<EOF > "$OVERLAY/recurse3"
set -e
echo \$SNAPPY_PRELOAD
echo \$LD_PRELOAD
export LD_PRELOAD=xxx
count=\$1
count=\$((count-1))
if [ \$count -ge 0 ]; then
    \$0 \$count
fi
EOF
chmod a+x "$OVERLAY/recurse3"
RECURSE_OUTPUT=$(LD_PRELOAD=$PRELOAD sh -c "$UNDERLAY/recurse3 1" | tr '\n' ' ')
test "$RECURSE_OUTPUT" = "$SNAPPY_PRELOAD $PRELOAD $SNAPPY_PRELOAD xxx:$PRELOAD "

cat <<EOF > "$OVERLAY/recurse4"
set -e
echo \$SNAPPY_PRELOAD
echo \$LD_PRELOAD
unset SNAPPY_PRELOAD
export LD_PRELOAD=xxx
count=\$1
count=\$((count-1))
if [ \$count -ge 0 ]; then
    \$0 \$count
fi
EOF
chmod a+x "$OVERLAY/recurse4"
RECURSE_OUTPUT=$(LD_PRELOAD=$PRELOAD:xxx:/xxx$PRELOAD sh -c "$UNDERLAY/recurse4 1" | tr '\n' ' ')
test "$RECURSE_OUTPUT" = "$SNAPPY_PRELOAD $PRELOAD:xxx:/xxx$PRELOAD $SNAPPY_PRELOAD xxx:$PRELOAD:/xxx$PRELOAD "
