#!/system/bin/sh
SKIPUNZIP=0

ui_print "****************************************"
ui_print "*   Rosemary VoWiFi & WOD Fix Module   *"
ui_print "*   for Redmi Note 10S (MT6785)        *"
ui_print "****************************************"

ui_print "- Installing files to system overlay..."

# Set binary and library permissions
set_perm $MODPATH/system/vendor/bin/epdg_wod 0 0 0755 u:object_r:epdg_wod_exec:s0
set_perm $MODPATH/system/vendor/lib64/libwo.so 0 0 0644 u:object_r:vendor_file:s0
set_perm $MODPATH/system/vendor/etc/init/init.wod.rc 0 0 0644 u:object_r:vendor_configs_file:s0
set_perm $MODPATH/system/vendor/etc/init/init.wfc-capability-override.rc 0 0 0644 u:object_r:vendor_configs_file:s0
set_perm $MODPATH/system/system_ext/etc/mtkimsprobe.dex 0 0 0644 u:object_r:system_file:s0

# Set script permissions
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print "- Applying SELinux contexts..."
chcon u:object_r:epdg_wod_exec:s0 $MODPATH/system/vendor/bin/epdg_wod 2>/dev/null
chcon u:object_r:vendor_file:s0 $MODPATH/system/vendor/lib64/libwo.so 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc/init/init.wod.rc 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc/init/init.wfc-capability-override.rc 2>/dev/null
chcon u:object_r:system_file:s0 $MODPATH/system/system_ext/etc/mtkimsprobe.dex 2>/dev/null

ui_print "- Injecting persistent CarrierConfig overrides for all SIM slots..."
for slot in 0 1; do
    cmd phone cc set-value -s $slot -p carrier_wfc_ims_available_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p carrier_wfc_supports_wifi_only_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p carrier_default_wfc_ims_enabled_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p carrier_volte_available_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p carrier_volte_provisioned_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p imsserviceentitlement.skip_wfc_activation_bool true 2>/dev/null
    cmd phone cc set-value -s $slot -p editable_wfc_mode_bool true 2>/dev/null
done

# Enable global settings
settings put global wfc_ims_enabled 1 2>/dev/null
settings put global wfc_ims_mode 2 2>/dev/null

ui_print "- VoWiFi fix successfully staged!"
ui_print "- Reboot your device to start epdg_wod & IMS registration."
