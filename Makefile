#
# Maintenance Makefile
#

#
# Global Setup
#
# This section sets some global parameters that get rid of some old `make`
# annoyences.
#
#     SHELL
#         We standardize on `bash` for better inline scripting capabilities,
#         and we always enable `pipefail`, to make sure individual failures
#         in a pipeline will be treated as failure.
#
#     .SECONDARY:
#         An empty SECONDARY target signals gnu-make to keep every intermediate
#         files around, even on failure. We want intermediates to stay around
#         so we get better caching behavior.
#

SHELL			:= /bin/bash -eo pipefail

.SECONDARY:

#
# Parameters
#
# The set of global parameters that can be controlled by the caller and the
# calling environment.
#
#     BUILDDIR
#         Path to the directory used to store build artifacts. This defaults
#         to `./data`, so all artifacts are stored in a subdirectory that can
#         be easily cleaned.
#
#     SRCDIR
#         Path to the source code directory. This defaults to `.`, so it
#         expects `make` to be called from within the source directory.
#
#     BIN_*
#         For all binaries that are executed as part of this makefile, a
#         variable called `BIN_<exe>` defines the path or name of the
#         executable. By default, they are set to the name of the binary.
#

BUILDDIR		?= ./data
SRCDIR			?= .

BIN_DOCKER		?= docker
BIN_FILE		?= file
BIN_ID			?= id
BIN_MKDIR		?= mkdir
BIN_RM			?= rm
BIN_TEST		?= test
BIN_ZOLA		?= zola

#
# Generic Targets
#
# The following is a set of generic targets used across the makefile. The
# following targets are defined:
#
#     help
#         This target prints all supported targets. It is meant as
#         documentation of targets we support and might use outside of this
#         repository.
#         This is also the default target.
#
#     $(BUILDDIR)/
#     $(BUILDDIR)/%/
#         This target simply creates the specified directory. It is limited to
#         the build-dir as a safety measure. Note that this requires you to use
#         a trailing slash after the directory to not mix it up with regular
#         files. Lastly, you mostly want this as order-only dependency, since
#         timestamps on directories do not affect their content.
#
#     FORCE
#         Dummy target to use as dependency to force `.PHONY` behavior on
#         targets that cannot use `.PHONY`.
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
	@echo "    test-statics:       Verify all static artifacts are valid"

$(BUILDDIR)/:
	$(BIN_MKDIR) -p "$@"

$(BUILDDIR)/%/:
	$(BIN_MKDIR) -p "$@"

.PHONY: FORCE
FORCE:

#
# Test Statics
#
# This contains availability and content tests for static paths in the
# builddir. This is used to ensure any paths we expose to the outside remain
# available in this repository and we do not suddenly break links (or if we
# break them, we have to explicitly do so by changing these tests).
#
# Basic content-verification is placed here, but elaborate tests belong into
# the generator-based tests for each data type.
#

BIN_FILE_MIME = $(BIN_FILE) --brief --mime --

.PHONY: test-statics
test-statics:
	$(BIN_TEST) "$$($(BIN_FILE_MIME) $(BUILDDIR)/images/logo_dark.png)" = "image/png; charset=binary"
	$(BIN_TEST) "$$($(BIN_FILE_MIME) $(BUILDDIR)/images/logo_dark_32.ico)" = "image/vnd.microsoft.icon; charset=binary"
	$(BIN_TEST) "$$($(BIN_FILE_MIME) $(BUILDDIR)/images/logo_dark_32.png)" = "image/png; charset=binary"
	$(BIN_TEST) "$$($(BIN_FILE_MIME) $(BUILDDIR)/images/logo_dark_400.png)" = "image/png; charset=binary"
	$(BIN_TEST) "$$($(BIN_FILE_MIME) $(BUILDDIR)/images/logo_light.png)" = "image/png; charset=binary"

#
# SSG Builds
#
# The static-site-generator used for `src/ssg/` is `zola`. We generate the
# full build in `data/ssg/` either via a local invocation or with a container
# to avoid local installs.
#

SSG_CONTAINER_ZOLA	?= ghcr.io/getzola/zola:v0.16.1

.PHONY: ssg-build
ssg-build:
	$(BIN_RM) -rf "$(BUILDDIR)/ssg"
	$(BIN_ZOLA) \
		--root "$(SRCDIR)/src/ssg" \
		build \
			--output-dir "$(BUILDDIR)/ssg"

.PHONY: ssg-build-docker
ssg-build-docker:
	$(BIN_RM) -rf "$(BUILDDIR)/ssg"
	$(BIN_DOCKER) \
		run \
			--interactive \
			--rm \
			--user "$$($(BIN_ID) -u):$$($(BIN_ID) -g)" \
			--volume "$(abspath $(BUILDDIR)):/srv/build" \
			--volume "$(abspath $(SRCDIR)):/srv/src" \
			"$(SSG_CONTAINER_ZOLA)" \
				--root "/srv/src/src/ssg" \
				build \
					--output-dir "/srv/build/ssg"

.PHONY: ssg-serve
ssg-serve:
	$(BIN_ZOLA) \
		--root "$(SRCDIR)/src/ssg" \
		serve
