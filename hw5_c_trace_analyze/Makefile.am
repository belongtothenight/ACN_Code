SUBDIRS = src

EXTRA_DIST = m4/.keepdir
ACLOCAL_AMFLAGS = -I m4 --install

pkgname = $(PACKAGE_TARNAME)-$(PACKAGE_VERSION)
tarname = $(pkgname).tar.gz

$(tarname):
	git archive --format=tar --prefix=$(pkgname)/ v$(PACKAGE_VERSION) $(FILES) | gzip > $@

tar: $(tarname)

clean-local:
	rm -rf \
		autoscan.log \
		aclocal.m4 \
		autom4te.cache \
		build-aux \
		config.h \
		config.h.in \
		config.h.in~ \
		config.log \
		config.status \
		configure \
		libtool \
		m4/* \
		.deps \
		Makefile.in \
		Makefile \
		stamp-h1 \
		src/*.in \
		src/*.o \
		src/*.la \
		src/*.lo \
		src/main \
		src/.deps \
		src/.libs \
		src/Makefile
	mkdir -p m4
	touch m4/.keepdir
	rm -rf \
		configure~ \
		*.tar.gz
