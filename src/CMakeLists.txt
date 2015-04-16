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

add_library(snappypreload64 SHARED preload.c)
set_target_properties(snappypreload64 PROPERTIES
                      COMPILE_FLAGS "-DSNAPPY_LIBNAME=\\\"libsnappypreload.so\\\" -m64")
target_link_libraries(snappypreload64 -ldl)

add_library(snappypreload32 SHARED preload.c)
set_target_properties(snappypreload32 PROPERTIES
                      COMPILE_FLAGS "-DSNAPPY_LIBNAME=\\\"libsnappypreload32.so\\\" -m32")
target_link_libraries(snappypreload32 -ldl -m32)
