
# Copyright (C) 2023, John Clark <inindev@gmail.com>

LINUX_VER = 6.7-rc7
LINUX_SHA256 = d0c92280db03d6f776d6f67faf035eba904bc5f2a04a807dfab77d1ebce39b02


ifneq (,$(findstring -rc,$(LINUX_VER)))
    LINUX_FILE = linux-$(LINUX_VER).tar.gz
    LINUX_URL  = https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/$(LINUX_FILE)
else
    LINUX_FILE = linux-$(LINUX_VER).tar.xz
    LINUX_URL  = https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_FILE)
endif
LDIR = kernel-$(LINUX_VER)/linux-$(LINUX_VER)


all: check_prereqs $(LDIR)
	$(MAKE) build

configure:
	@echo "\n\033[1m\033[33mconfiguring source tree...\033[m"
	@test -z $(kver) || echo $(kver) > $(LDIR)/.version
	# todo: config fixups?
	$(MAKE) -C $(LDIR) ARCH=arm64 inindev_defconfig

build: configure
	@echo "\n\033[1m\033[33mbeginning compile...\033[m"
	@kv="$$(make --no-print-directory -C $(LDIR) kernelversion)"; \
	bv="$$(expr "$$(cat $(LDIR)/.version 2>/dev/null || echo 0)" + 1 2>/dev/null)"; \
	export SOURCE_DATE_EPOCH="$$(stat -c %Y $(LDIR)/README)"; \
	export KDEB_CHANGELOG_DIST='stable'; \
	export KBUILD_BUILD_TIMESTAMP="Debian $$kv-$$bv $$(date -d @$$SOURCE_DATE_EPOCH +'(%Y-%m-%d)')"; \
	export KBUILD_BUILD_HOST='github.com/inindev'; \
	export KBUILD_BUILD_USER='linux-kernel'; \
	export KBUILD_BUILD_VERSION="$$bv"; \
	\
	t1=$$(date +%s); \
	nice $(MAKE) -C $(LDIR) -j"$$(nproc)" CC="$$(readlink /usr/bin/gcc)" bindeb-pkg KBUILD_IMAGE='arch/arm64/boot/Image' LOCALVERSION="-$$bv-arm64"; \
	t2=$$(date +%s); \
	\
	echo "\n\033[36mkernel package ready (elapsed: $$(date -d@$$((t2-t1)) '+%H:%M:%S'))\033[35m"; \
	ln -sfv "kernel-$(LINUX_VER)/linux-image-$$kv-$$bv-arm64_$$kv-$${bv}_arm64.deb"; \
	ln -sfv "kernel-$(LINUX_VER)/linux-headers-$$kv-$$bv-arm64_$$kv-$${bv}_arm64.deb"; \
	echo "\033[m"

# unpack and patch linux tar
$(LDIR): downloads/$(LINUX_FILE)
	@tar --one-top-level=kernel-$(LINUX_VER) -xavf downloads/$(LINUX_FILE)
	# $(MAKE) -C $(LDIR) mrproper

	@echo "\n==> patching..."
	@for patch in patches/*.patch; do \
	    echo "\n\033[32m$$patch\033[m"; \
	    patch -p1 -d $(LDIR) -i "../../$$patch"; \
	done

	@touch $(LDIR)

# download linux tar
downloads/$(LINUX_FILE):
	@echo "\n==> downloading $(LINUX_FILE)...\n"
	@curl -O --create-dirs --output-dir downloads $(LINUX_URL)
	@echo "\n==> checking sha256 $(LINUX_SHA256)..."
	@sha=$$(sha256sum "downloads/linux-$(LINUX_VER).tar.gz" | cut -c1-64); \
	test "_$(LINUX_SHA256)" = "_$$sha" || { echo "error: invalid sha256 $$sha"; exit 5; }

check_prereqs:
	@todo=""; \
	for item in screen bc build-essential debhelper flex bison pahole python3 rsync libncurses-dev libelf-dev libssl-dev lz4 zstd; do \
	    dpkg -l "$$item" 2>/dev/null | grep -q "ii  $$item" || todo="$$todo $$item"; \
	done; \
	\
	if ! test -z "$$todo"; then \
	    echo "the following packages need to be installed:\033[1m\033[33m$$todo\033[m"; \
	    echo "   run: \033[1m\033[32msudo apt update && sudo apt -y install$$todo\033[m\n"; \
	    exit 1; \
	fi

ifeq (,$(STY)$(TMUX))
	$(error please start a screen or tmux session)
endif

clean:
	@echo "\n==> cleaning..."
	@echo "removing kernel-$(LINUX_VER)..."
	@rm -rf kernel-$(LINUX_VER)
	@echo


.PHONY: all configure build check_prereqs clean
