BASEDIR ?= $(CURDIR)
DESTDIR ?= $(BASEDIR)/bin/local
BAKE_TARGET ?= pkg

word-hypen = $(word $2,$(subst -, ,$1))

.PHONY: pkg-%
pkg-%:
	$(eval pkg_type=$(call word-hypen,$*,1))
	$(eval pkg_release=$(call word-hypen,$*,2))
	PKG_TYPE=$(pkg_type) PKG_RELEASE=$(pkg_release) DESTDIR=$(DESTDIR) docker buildx bake $(BAKE_TARGET)

.PHONY: cross-%
pkg-cross-%:
	$(eval pkg_type=$(call word-hypen,$*,1))
	$(eval pkg_release=$(call word-hypen,$*,2))
	$(eval target=pkg-$(pkg_type)-$(pkg_release))
	$(eval $@_TMP_OUT := $(shell mktemp -d -t docker-packaging.XXXXXXXXXX))
	$(MAKE) $(target:%-=%) DESTDIR=$($@_TMP_OUT) BAKE_TARGET=pkg-cross
	$(eval DESTDIR = $(BASEDIR)/bin/$(pkg_type))
	mkdir -p $(DESTDIR)
	find $($@_TMP_OUT) -mindepth 2 -maxdepth 2 -type d -exec cp -rf {} $(DESTDIR)/ ';'
	find $(DESTDIR) -type d -empty -delete
	rm -rf "$($@_TMP_OUT)"
