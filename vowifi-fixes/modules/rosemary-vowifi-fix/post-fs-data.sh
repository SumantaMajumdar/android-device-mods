#!/system/bin/sh
MODDIR=${0%/*}

# Re-enforce SELinux contexts on magic-mounted vendor files
chcon u:object_r:epdg_wod_exec:s0 /vendor/bin/epdg_wod 2>/dev/null
chcon u:object_r:vendor_file:s0 /vendor/lib64/libwo.so 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 /vendor/etc/init/init.wod.rc 2>/dev/null
chcon u:object_r:vendor_configs_file:s0 /vendor/etc/init/init.wfc-capability-override.rc 2>/dev/null
chcon u:object_r:system_file:s0 /system_ext/etc/mtkimsprobe.dex 2>/dev/null
