################################################################################
#
# hello-world test package
#
################################################################################

HELLO_WORLD_VERSION = 1.0
# Tell Buildroot to skip downloading from the web and just build a local C file
HELLO_WORLD_SITE_METHOD = local
HELLO_WORLD_SITE = $(BR2_EXTERNAL_CUSTOM_BR_FRAMEWORK_PATH)/package/hello-world/src

define HELLO_WORLD_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		$(HELLO_WORLD_SITE)/hello.c -o $(@D)/hello_test
enddefine

define HELLO_WORLD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hello_test $(TARGET_DIR)/usr/bin/hello_test
enddefine

$(eval $(generic-package))
