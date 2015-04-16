# -*- Mode: Makefile; indent-tabs-mode: t; tab-width: 2 -*-
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

all: builddir
	cd builddir && make

builddir:
	mkdir -p builddir
	cd builddir && cmake ..

clean:
	rm -r builddir

check: all
	@make -C builddir test

%: builddir
	@[ "$@" = "Makefile" ] || make -C builddir $@

.PHONY: builddir check clean
