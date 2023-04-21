PROJECT ?= bsp
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
MANDIR ?= $(PREFIX)/share/man

.PHONY: all
all: build

#
# Test
#
.PHONY: test
test:
	#find ./lib ./bsp -type f \( -name "*.sh" -o -name "bsp" \) -exec shellcheck {} +

#
# Build
#
.PHONY: build
build: build-man build-doc

SRC-MAN		:=	man
SRCS-MAN	:=	$(wildcard $(SRC-MAN)/*.md)
MANS		:=	$(SRCS-MAN:.md=)
.PHONY: build-man
build-man: $(MANS)

$(SRC-MAN)/%: $(SRC-MAN)/%.md
	pandoc "$<" -o "$@" --from markdown --to man -s

SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE
.PHONY: build-doc
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-man clean-doc clean-deb

.PHONY: clean-man
clean-man:
	rm -rf $(MANS)

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	gbp dch --debian-branch=main

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b
