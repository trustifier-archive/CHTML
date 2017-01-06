-include Makefile

ifeq ($(AUTOMAKE),)

gm-build-builder: config.h.in Makefile

Makefile: config.h.in Makefile.in config.status
	@echo "Auto-building Makefile"
	./config.status $@

config.status: configure
	@echo "Starting configure"
	./configure --no-create --no-recursion

configure: configure.ac aclocal.m4
	@echo "Auto-building configure"
	autoconf

aclocal.m4: acinclude.m4
	@echo "Auto-building aclocal"
	aclocal

config.h.in: configure.ac aclocal.m4
	@echo "Auto-building config.h.in"
	autoheader


Makefile.in: aclocal.m4 Makefile.am
	echo "Auto-building Makefile.in"
	automake -c -a
endif
