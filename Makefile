# ==============================================================================
#  BUILDROOT INVERTED SDK MASTER ENGINE
# ==============================================================================

# Centralized release tracking versions table - Modify ONLY here to shift baselines
BR_LTS_VER       := 2025.02
BR_STABLE_VER    := 2025.08
BR_CANDIDATE_VER := 2025.11

BR_DIR           := $(CURDIR)/.buildroot-core
BOOTSTRAP_SCRIPT := $(CURDIR)/support/scripts/bootstrap.sh

.PHONY: all sysconfig repoclean lts stable candidate bootstrap_sandbox

# ------------------------------------------------------------------------------
#  Main Entry Execution Targets
# ------------------------------------------------------------------------------

all:
	@if [ ! -d "$(BR_DIR)" ]; then \
		echo "[-] Error: Core sandbox missing. Run 'make sysconfig' or an explicit target first."; \
		exit 1; \
	fi
	@echo "[*] Triggering Buildroot with Local External Bindings..."
	@if [ -f $(CURDIR)/configs/generic_x86_64_defconfig ]; then \
		$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) generic_x86_64_defconfig; \
	fi
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR)

sysconfig: lts

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
#  Destruction Safeguards
# ------------------------------------------------------------------------------
repoclean:
	@echo -n "WARNING: This will completely nuke your cached core environment (.buildroot-core) and files. Continue? [y/N]: " && read ans && \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		echo "[*] Purging workspace components safely..."; \
		rm -rf $(BR_DIR); \
		echo "[+] Workspace cleared."; \
	else \
		echo "[*] Operation cancelled. Core environment preserved."; \
	fi
