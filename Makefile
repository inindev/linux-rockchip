#
# Copyright (C) 2026, John Clark <inindev@gmail.com>
#

LINUX_VER    = 6.19.5
LINUX_SHA256 = 95ae05c8c709e353c0e8506c072efc5598d85b8b7b564a1ebac7ee8345042ffa


LDIR = kernel-$(LINUX_VER)/linux-$(LINUX_VER)

ifeq ($(findstring -rc,$(LINUX_VER)),)
    LINUX_FILE = linux-$(LINUX_VER).tar.xz
    LINUX_URL  = https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_FILE)
else
    LINUX_FILE = linux-$(LINUX_VER).tar.gz
    LINUX_URL  = https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/$(LINUX_FILE)
endif

.PHONY: all configure build check_prereqs clean

all: check_prereqs $(LDIR)
	$(MAKE) build

configure:
	@echo "$(h1)Configuring source tree...$(rst)"
	@test -z "$(kver)" || echo "$(kver)" > "$(LDIR)/.version"
	$(MAKE) -C "$(LDIR)" ARCH=arm64 inindev_defconfig
	@opts="$(CONFIG_OPTS)"; \
	if [ -f "custom_config" ]; then \
	    echo "$(h1)Applying options from custom_config...$(rst)"; \
	    opts="$$opts $$(cat custom_config)"; \
	fi; \
	if [ -n "$$opts" ]; then \
	    echo "$(h1)Applying custom config options...$(rst)"; \
	    "$(LDIR)/scripts/config" --file "$(LDIR)/.config" $$opts; \
	    $(MAKE) -C "$(LDIR)" ARCH=arm64 olddefconfig; \
	fi

build: configure
	@echo "$(h1)Beginning compile...$(rst)"
	@kernel_ver=$$($(MAKE) --no-print-directory -C "$(LDIR)" kernelversion); \
	build_ver=$$(expr "$$(cat "$(LDIR)/.version" 2>/dev/null || echo 0)" + 1 2>/dev/null); \
	SOURCE_DATE_EPOCH=$$(stat -c %Y "$(LDIR)/README"); \
	KDEB_CHANGELOG_DIST=stable; \
	KBUILD_BUILD_TIMESTAMP="Debian $$kernel_ver-$$build_ver $$(date -ud @$$SOURCE_DATE_EPOCH +'(%Y-%m-%d)')"; \
	KBUILD_BUILD_HOST=github.com/inindev; \
	KBUILD_BUILD_USER=linux-kernel; \
	KBUILD_BUILD_VERSION=$$build_ver; \
	start_time=$$(date +%s); \
	nice $(MAKE) -C "$(LDIR)" -j$$(nproc) CC=$$(readlink /usr/bin/gcc) \
	    bindeb-pkg KBUILD_IMAGE=arch/arm64/boot/Image LOCALVERSION="-$$build_ver-arm64"; \
	elapsed=$$(($$(date +%s) - start_time)); \
	el_hr=$$((elapsed / 3600)); \
	el_min=$$(((elapsed % 3600) / 60)); \
	el_sec=$$((elapsed % 60)); \
	echo "$(cya)Kernel package ready (elapsed: $$el_hr:$$el_min:$$el_sec)$(rst)";

$(LDIR): | downloads/$(LINUX_FILE)
	@echo "$(h1)Checking SHA256 $(LINUX_SHA256)...$(rst)"
	@sha=$$(sha256sum "downloads/$(LINUX_FILE)" | cut -c1-64); \
	if [ "_$(LINUX_SHA256)" != "_$$sha" ]; then \
	    echo "Error: Invalid SHA256 $$sha"; \
	    exit 5; \
	fi
	@tar --one-top-level=kernel-$(LINUX_VER) -xavf "downloads/$(LINUX_FILE)"
	@echo "$(h1)Patching...$(rst)"
	@patches=$$(find patches -name '*.patch' 2>/dev/null | sort); \
	for patch in $$patches; do \
	    echo "$(grn)$$patch$(rst)"; \
	    patch -p1 -d "$(LDIR)" -i "../../$$patch"; \
	done

downloads/$(LINUX_FILE):
	@echo "$(h1)Downloading $(LINUX_FILE)...$(rst)"
	@curl -O --create-dirs --output-dir downloads "$(LINUX_URL)"

check_prereqs:
	@missing=""; \
	for pkg in screen bc build-essential debhelper flex bison pahole python3 rsync libdw-dev libelf-dev libncurses-dev libssl-dev lz4 zstd; do \
	    dpkg -l "$$pkg" 2>/dev/null | grep -q "ii  $$pkg" || missing="$$missing $$pkg"; \
	done; \
	if [ -n "$$missing" ]; then \
	    echo "The following packages need to be installed:$(bld)$(yel)$$missing$(rst)"; \
	    echo "   Run: $(bld)$(grn)sudo apt update && sudo apt -y install$$missing$(rst)"; \
	    exit 1; \
	fi

clean:
	@echo "$(h1)Cleaning...$(rst)"; \
	for dir in kernel-*; do \
	    if [ -d "$$dir" ]; then \
	        echo "Removing $$dir..."; \
	        rm -rf "$$dir"; \
	    fi; \
	done

# require linux
UNAME_S := $(shell uname -s)
ifneq ($(UNAME_S),Linux)
    $(error This project requires a Linux system, but '$(UNAME_S)' was detected)
endif

# require arm64
UNAME_M := $(shell uname -m)
ifneq ($(UNAME_M),aarch64)
    $(error This project requires an ARM64 architecture, but '$(UNAME_M)' was detected)
endif

# reqire tmux
ifeq (,$(STY)$(TMUX))
    $(error Please start a screen or tmux session)
endif

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
