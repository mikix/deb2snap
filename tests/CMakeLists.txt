# -*- Mode: CMake; indent-tabs-mode: nil; tab-width: 4 -*-
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

set(PRELOAD "PRELOAD=${CMAKE_BINARY_DIR}/src/libsnappypreload.so")

macro(add_preload_test test_target test_command)
    set(full_command env ${PRELOAD} BUILDDIR=${CMAKE_BINARY_DIR} ${test_command} ${ARGN})
    add_custom_target(${test_target}
                      COMMAND ${full_command}
                      DEPENDS snappypreload)
    add_test(NAME ${test_target}
             COMMAND ${full_command})
endmacro()

add_preload_test(test-exec ${CMAKE_CURRENT_SOURCE_DIR}/exec.sh)
add_preload_test(test-overlay ${CMAKE_CURRENT_SOURCE_DIR}/overlay.sh)
