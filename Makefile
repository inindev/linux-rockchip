
# Copyright (C) 2023, John Clark <inindev@gmail.com>

LINUX_VER = 6.7-rc8
LINUX_SHA256 = 4306cbb1b33b2fd67a86d9a3e4faba9a95413398c3d9cf57991ee97800a0640a

LDIR = kernel-$(LINUX_VER)/linux-$(LINUX_VER)

ifneq (,$(findstring -rc,$(LINUX_VER)))
    LINUX_FILE = linux-$(LINUX_VER).tar.gz
    LINUX_URL  = https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/$(LINUX_FILE)
else
    LINUX_FILE = linux-$(LINUX_VER).tar.xz
    LINUX_URL  = https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_FILE)
endif


all: check_prereqs $(LDIR)
	$(MAKE) build

configure:
	@echo "\n$(h1)configuring source tree...$(rst)"
	@test -z $(kver) || echo $(kver) > $(LDIR)/.version
	# todo: config fixups?
	$(MAKE) -C $(LDIR) ARCH=arm64 inindev_defconfig

build: configure
	@echo "\n$(h1)beginning compile...$(rst)"
	@kv="$$(make --no-print-directory -C $(LDIR) kernelversion)"; \
	bv="$$(expr "$$(cat $(LDIR)/.version 2>/dev/null || echo 0)" + 1 2>/dev/null)"; \
	\
	export SOURCE_DATE_EPOCH="$$(stat -c %Y $(LDIR)/README)"; \
	export KDEB_CHANGELOG_DIST='stable'; \
	export KBUILD_BUILD_TIMESTAMP="Debian $$kv-$$bv $$(date -ud @$$SOURCE_DATE_EPOCH +'(%Y-%m-%d)')"; \
	export KBUILD_BUILD_HOST='github.com/inindev'; \
	export KBUILD_BUILD_USER='linux-kernel'; \
	export KBUILD_BUILD_VERSION="$$bv"; \
	\
	t1=$$(date +%s); \
	nice $(MAKE) -C $(LDIR) -j"$$(nproc)" CC="$$(readlink /usr/bin/gcc)" bindeb-pkg KBUILD_IMAGE='arch/arm64/boot/Image' LOCALVERSION="-$$bv-arm64"; \
	t2=$$(date +%s); \
	\
	echo "\n$(cya)kernel package ready (elapsed: $$(date -d@$$((t2-t1)) '+%H:%M:%S'))$(rst)\n"

# unpack and patch linux tar
$(LDIR): | downloads/$(LINUX_FILE)
	@tar --one-top-level=kernel-$(LINUX_VER) -xavf downloads/$(LINUX_FILE)

	@echo "\n$(h1)patching...$(rst)"
	@patches="$$(find patches -maxdepth 2 -name '*.patch' 2>/dev/null | sort)"; \
	for patch in $$patches; do \
	    echo "\n$(grn)$$patch$(rst)"; \
	    patch -p1 -d $(LDIR) -i "../../$$patch"; \
	done

# download linux tar
downloads/$(LINUX_FILE):
	@echo "\n$(h1)downloading $(LINUX_FILE)...$(rst)\n"
	@curl -O --create-dirs --output-dir downloads $(LINUX_URL)
	@echo "\n$(h1)checking sha256 $(LINUX_SHA256)...$(rst)"
	@sha=$$(sha256sum "downloads/linux-$(LINUX_VER).tar.gz" | cut -c1-64); \
	test "_$(LINUX_SHA256)" = "_$$sha" || { echo "error: invalid sha256 $$sha"; exit 5; }

check_prereqs:
	@todo=""; \
	for item in screen bc build-essential debhelper flex bison pahole python3 rsync libncurses-dev libelf-dev libssl-dev lz4 zstd; do \
	    dpkg -l "$$item" 2>/dev/null | grep -q "ii  $$item" || todo="$$todo $$item"; \
	done; \
	\
	if ! test -z "$$todo"; then \
	    echo "the following packages need to be installed:$(bld)$(yel)$$todo$(rst)"; \
	    echo "   run: $(bld)$(grn)sudo apt update && sudo apt -y install$$todo$(rst)\n"; \
	    exit 1; \
	fi

ifeq (,$(STY)$(TMUX))
	$(error please start a screen or tmux session)
endif

clean:
	@echo "\n$(h1)cleaning...$(rst)"
	@echo "removing kernel-$(LINUX_VER)..."
	@rm -rf kernel-$(LINUX_VER)
	@echo


.PHONY: all configure build check_prereqs clean


# colors
rst := [m
bld := [1m
red := [31m
grn := [32m
yel := [33m
blu := [34m
mag := [35m
cya := [36m
h1  := $(blu)==>$(rst) $(bld)
