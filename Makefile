# ==============================================================================
#  BUILDROOT INVERTED SDK MASTER ENGINE
# ==============================================================================

# Lock down exact Buildroot LTS version to guarantee 100% binary reproducibility
BR_VERSION = 2026.02
BR_DIR     = $(CURDIR)/.buildroot-core
BR_URL     = https://buildroot.org

.PHONY: all sysconfig sync_br clean

# Default execution target downloads and checks for existing defconfigs automatically
all: sync_br
	@echo "[*] Triggering Buildroot with Local External Bindings..."
	@if [ -f $(CURDIR)/configs/generic_x86_64_defconfig ]; then \
		$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) generic_x86_64_defconfig; \
	fi
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR)

# Pull down core Buildroot archive silently into .gitignore safety if missing
sync_br:
	@if [ ! -d "$(BR_DIR)" ]; then \
		echo "[*] Fetching Pure Buildroot Core Source v$(BR_VERSION)..."; \
		mkdir -p $(BR_DIR); \
		curl -sL $(BR_URL) | tar -xJ --strip-components=1 -C $(BR_DIR); \
	fi

# Bridge to expose standard graphic menuconfig commands cleanly up to root shell
sysconfig: sync_br
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) menuconfig
	@echo "[*] Exporting custom configuration state back to local workspace..."
	@mkdir -p $(CURDIR)/configs
	@$(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR) savedefconfig
	@cp -f $(BR_DIR)/defconfig $(CURDIR)/configs/generic_x86_64_defconfig

clean:
	@if [ -d "$(BR_DIR)" ]; then $(MAKE) -C $(BR_DIR) clean; fi

repoclean:
	@if [ -d "$(BR_DIR)" ]; then rm -rf $(BR_DIR) ; fi
