# ==============================================================================
#  BUILDROOT INVERTED SDK MASTER ENGINE & PROXY ROUTER
# ==============================================================================

# Centralized release tracking versions table - Modify ONLY here to shift baselines
BR_LTS_VER       := 2025.02
BR_STABLE_VER    := 2025.08
BR_CANDIDATE_VER := 2025.11

BR_DIR           := $(CURDIR)/.buildroot-core
BOOTSTRAP_SCRIPT := $(CURDIR)/support/scripts/bootstrap.sh
README_FILE      := $(CURDIR)/README.md


# ------------------------------------------------------------------------------
#  Deal with GCC Version issues
# ------------------------------------------------------------------------------
# Detect if the host system compiler is GCC 15 or newer
HOST_GCC_VERSION := $(shell gcc -dumpversion | cut -d. -f1)

ifeq ($(shell expr $(HOST_GCC_VERSION) \>= 15), 1)
    # Inject the older standard into Buildroot's global host flags
    export HOST_CFLAGS += -std=gnu17
    export HOST_CXXFLAGS += -std=gnu17
endif

.PHONY: all sysconfig repoclean lts stable candidate bootstrap_sandbox help

# ------------------------------------------------------------------------------
#  Main Entry Execution Targets
# ------------------------------------------------------------------------------

# Pure empty entry rule maps straight to standard cross-compilation pipeline
all:
	@if [ ! -d "$(BR_DIR)" ]; then \
		echo "[-] Error: Core sandbox missing. Run 'make sysconfig' or 'make lts' first."; \
		exit 1; \
	fi
	@echo "[*] Triggering Buildroot with Local External Bindings..."
	@if [ -f $(CURDIR)/configs/generic_x86_64_defconfig ]; then \
		$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) generic_x86_64_defconfig; \
	fi
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR)

sysconfig: lts
%_defconfig: lts

# ------------------------------------------------------------------------------
#  Explicit Release Stream Selectors (Binds parameters text cleanly to target)
# ------------------------------------------------------------------------------
lts:       BR_VER_STR := $(BR_LTS_VER)
lts:       BR_TYPE_STR := LTS
lts:       bootstrap_sandbox

stable:    BR_VER_STR := $(BR_STABLE_VER)
stable:    BR_TYPE_STR := Stable
stable:    bootstrap_sandbox

candidate: BR_VER_STR := $(BR_CANDIDATE_VER)
candidate: BR_TYPE_STR := Candidate
candidate: bootstrap_sandbox

# ------------------------------------------------------------------------------
#  Orchestration Script Execution Handoff Pass
# ------------------------------------------------------------------------------
bootstrap_sandbox:
	@bash $(BOOTSTRAP_SCRIPT) "$(BR_TYPE_STR)" "$(BR_VER_STR)" "$(BR_DIR)"
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) menuconfig
	@echo "[*] Exporting custom configuration state back to local workspace..."
	@mkdir -p $(CURDIR)/configs
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) savedefconfig
	@cp -f $(BR_DIR)/defconfig $(CURDIR)/configs/generic_x86_64_defconfig


# ------------------------------------------------------------------------------
#  Dynamic Defconfig Initializer Loop
# ------------------------------------------------------------------------------
# Catch individual board profiles, initialize under LTS rules, and pass it down
%_defconfig:
	@if [ ! -d "$(BR_DIR)" ]; then \
		echo "[*] Workspace uninitialized. Bootstrapping LTS profile for $@..."; \
		$(MAKE) BR_TYPE_STR=LTS BR_VER_STR=$(BR_LTS_VER) bootstrap_defconfig; \
	fi
	@echo "[*] Appending Profile: $@"
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) $@

# Hidden staging rule to clean up bootstrap parameter passing
bootstrap_defconfig:
	@bash $(BOOTSTRAP_SCRIPT) "$(BR_TYPE_STR)" "$(BR_VER_STR)" "$(BR_DIR)"

# ------------------------------------------------------------------------------
#  Interactive Self-Documentation Engine
# ------------------------------------------------------------------------------
help:
	@if [ -f "$(README_FILE)" ]; then \
		cat "$(README_FILE)"; \
	else \
		echo "=== BUILDROOT MASTER INVERTED SDK COMMANDS ==="; \
		echo "  make lts       - Bootstrap and configure Long Term Support kernel environment"; \
		echo "  make stable    - Bootstrap and configure Mainline Stable kernel environment"; \
		echo "  make candidate - Bootstrap and configure Bleeding Edge Candidate kernel environment"; \
		echo "  make help      - Render workspace project documentation metrics"; \
		echo "  make repoclean - Completely nuke internal sandboxes and build state"; \
		echo "  make <target>  - Pass any standard Buildroot commands directly down (e.g. menuconfig)"; \
	fi

# ------------------------------------------------------------------------------
#  Destruction Safeguards
# ------------------------------------------------------------------------------
repoclean:
	@echo -n "WARNING: This will completely nuke your cached core environment (.buildroot-core). Continue? [y/N]: " && read ans && \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		echo "[*] Purging workspace components safely..."; \
		rm -rf $(BR_DIR); \
		rm -rf .host-configured; \
		echo "[+] Workspace cleared."; \
	else \
		echo "[*] Clean cycle aborted. Core sandbox preserved."; \
	fi

# ------------------------------------------------------------------------------
#  The Catch-All Double-Colon Passthrough Engine (Proxies commands to Buildroot)
# ------------------------------------------------------------------------------
%::
	@if [ ! -d "$(BR_DIR)" ]; then \
		echo "[-] Error: Core sandbox missing. Run 'make sysconfig' or 'make lts' first to bootstrap."; \
		exit 1; \
	fi
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) HOSTCFLAGS="-Wno-format-overflow" $@

