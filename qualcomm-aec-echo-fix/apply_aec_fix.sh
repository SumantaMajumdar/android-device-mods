#!/system/bin/sh
TARGET="/vendor/etc/audio/sku_cape/resourcemanager_waipio_mtp.xml"
SRC="/data/adb/modules/qualcomm_aec_fix/system/vendor/etc/audio/sku_cape/resourcemanager_waipio_mtp.xml"

mount -o bind "$SRC" "$TARGET"
echo "Bind mount result: $?"

grep -n -C 3 'ext_ec_ref_enabled' "$TARGET" | head -n 15

pkill -f 'audioserver' || true
echo "audioserver reloaded"

