#!/system/bin/sh
MODDIR=${0%/*}

# Bind mount patched CarrierConfig.apk over system_ext early before PackageManager scans
if [ -f "$MODDIR/system_ext/priv-app/CarrierConfig/CarrierConfig.apk" ]; then
    mount -o bind "$MODDIR/system_ext/priv-app/CarrierConfig/CarrierConfig.apk" /system_ext/priv-app/CarrierConfig/CarrierConfig.apk
    chcon u:object_r:system_file:s0 /system_ext/priv-app/CarrierConfig/CarrierConfig.apk
fi
