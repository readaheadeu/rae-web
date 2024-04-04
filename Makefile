#
# Maintenance Makefile
#

# Enforce bash with fatal errors.
SHELL			:= /bin/bash -eo pipefail

# Keep intermediates around on failures for better caching.
.SECONDARY:

# Default build and source directories.
BUILDDIR		?= ./build
SRCDIR			?= .

#
# Build Images
#

# https://github.com/readaheadeu/rae-images/pkgs/container/rae-zola
IMG_ZOLA		?= ghcr.io/readaheadeu/rae-zola:latest

#
# Common Commands
#

DOCKER_RUN		= docker run --interactive --rm

DOCKER_RUN_SELF		= $(DOCKER_RUN) --user "$$(id -u):$$(id -g)"

#
# Common Functions
#

# Replace spaces with other characters in a list.
F_REPLACE_SPACE		= $(subst $(eval ) ,$2,$1)

#
# Target: help
#

.PHONY: help
help:
	@# 80-width marker:
	@#     01234567012345670123456701234567012345670123456701234567012345670123456701234567
	@echo "make [TARGETS...]"
	@echo
	@echo "This is the maintenance makefile of this project. The following"
	@echo "targets are available:"
	@echo
	@echo "    help:               Print this usage information."
	@echo
	@echo "    web-build:          Build the Zola-based website"
	@echo "    web-serve:          Serve the Zola-based website"
	@echo "    web-test:           Run the website test suite"

#
# Target: BUILDDIR
#

$(BUILDDIR)/:
	mkdir -p "$@"

$(BUILDDIR)/%/:
	mkdir -p "$@"

#
# Target: FORCE
#
# Used as alternative to `.PHONY` if the target is not fixed.
#

.PHONY: FORCE
FORCE:

#
# Target: web-*
#

WEB_TOPLEVEL = \
	s \
	w \
	404.html \
	index.html \
	robots.txt \
	sitemap.xml

.PHONY: web-build
web-build: $(BUILDDIR)/web/
	$(DOCKER_RUN_SELF) \
		--volume "$(abspath $(BUILDDIR)):/srv/build" \
		--volume "$(abspath $(SRCDIR)):/srv/src" \
		"$(IMG_ZOLA)" \
			--root "/srv/src/lib/web" \
			build \
			--force \
			--output-dir "/srv/build/web"

.PHONY: web-serve
web-serve: $(BUILDDIR)/web/
	$(DOCKER_RUN_SELF) \
		--publish "1111:1111" \
		--volume "$(abspath $(BUILDDIR)):/srv/build" \
		--volume "$(abspath $(SRCDIR)):/srv/src" \
		"$(IMG_ZOLA)" \
			--root "/srv/src/lib/web" \
			serve \
			--force \
			--interface "0.0.0.0" \
			--output-dir "/srv/build/web"

.PHONY: web-test
web-test:
	@# Test existance of the directory.
	test -d "$(BUILDDIR)/web"
	@# Verify that we know exactly what is placed on the root level.
	test "$$(ls "$(BUILDDIR)/web" | sort)" = \
		"$$( \
			printf \
			"$(call F_REPLACE_SPACE,$(sort $(WEB_TOPLEVEL)),\n)\n" \
		)"
	@# Verify known permalinks.
	test "$$(cat $(BUILDDIR)/web/index.html | file --brief --mime -)" = "text/html; charset=utf-8"
	test "$$(cat $(BUILDDIR)/web/404.html | file --brief --mime -)" = "text/html; charset=utf-8"
	test "$$(cat $(BUILDDIR)/web/robots.txt | file --brief --mime -)" = "text/plain; charset=us-ascii"
	test "$$(cat $(BUILDDIR)/web/sitemap.xml | file --brief --mime -)" = "text/xml; charset=us-ascii"
	@# Verify reserved redirects do not exist.
	test ! -e "$(BUILDDIR)/web/p"
