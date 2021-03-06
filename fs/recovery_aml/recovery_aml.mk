#############################################################
#
# tar + squashfs to archive target filesystem
#
#############################################################

ROOTFS_RECOVERY_AML_DEPENDENCIES = linux26 rootfs-tar_aml host-python

RECOVERY_AML_ARGS = -b $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_WIPE_USERDATA),y)
  RECOVERY_AML_ARGS += -w
endif
ifeq ($(BR2_TARGET_ROOTFS_RECOVERY_AML_WIPE_USERDATA_CONDITIONAL),y)
  RECOVERY_AML_ARGS += -c
endif

# We will initialize some vars here
AML_LOGO := fs/recovery_aml/aml_logo.img
UPDATE_PACKAGE := update.img
UPDATE_UNSIGNED := update-unsigned.img

# Set AML_LOGO if specified
ifneq ($(strip $(BR2_TARGET_AML_LOGO)),"")
  AML_LOGO := $(BR2_TARGET_AML_LOGO)
endif

# If boardname is f16ref, set update file with zip extension
ifeq ($(strip $(BR2_TARGET_ROOTFS_RECOVERY_AML_BOARDNAME)),"f16ref")
  UPDATE_PACKAGE := update.zip
  UPDATE_UNSIGNED := update-unsigned.zip
endif

define ROOTFS_RECOVERY_AML_CMD
 mkdir -p $(BINARIES_DIR)/aml_recovery/system && \
 tar -C $(BINARIES_DIR)/aml_recovery/system -xf $(BINARIES_DIR)/rootfs.tar && \
 mkdir -p $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 PYTHONDONTWRITEBYTECODE=1 $(HOST_DIR)/usr/bin/python fs/recovery_aml/android_scriptgen $(RECOVERY_AML_ARGS) -i -p $(BINARIES_DIR)/aml_recovery/system -o \
   $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/updater-script && \
 cp -f fs/recovery_aml/update-binary $(BINARIES_DIR)/aml_recovery/META-INF/com/google/android/ && \
 cp -f $(AML_LOGO) $(BINARIES_DIR)/aml_recovery/aml_logo.img && \
 cp -f $(BINARIES_DIR)/uImage-* $(BINARIES_DIR)/aml_recovery/ && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type l -delete && \
 find $(BINARIES_DIR)/aml_recovery/system/ -type d -empty -exec sh -c 'echo "dummy" > "{}"/.empty' \; && \
 pushd $(BINARIES_DIR)/aml_recovery/ >/dev/null && \
 zip -m -q -r -y $(BINARIES_DIR)/aml_recovery/$(UPDATE_UNSIGNED) aml_logo.img uImage-2.6.34 META-INF system && \
 popd >/dev/null && \
 echo "Signing $(UPDATE_PACKAGE)..." && \
 pushd fs/recovery_aml/ >/dev/null; java -Xmx1024m -jar signapk.jar -w testkey.x509.pem testkey.pk8 $(BINARIES_DIR)/aml_recovery/$(UPDATE_UNSIGNED) $(BINARIES_DIR)/$(UPDATE_PACKAGE) && \
 rm -rf $(BINARIES_DIR)/aml_recovery; rm -f $(TARGET_DIR)/usr.sqsh
endef

$(eval $(call ROOTFS_TARGET,recovery_aml))
