#!/system/bin/sh
echo "=== 1. Active resourcemanager XML ==="
grep -n -C 3 'ext_ec_ref_enabled' /vendor/etc/audio/sku_cape/resourcemanager_waipio_mtp.xml | head -n 12

echo "=== 2. Fluence and EC properties ==="
getprop | grep -iE 'fluence|dynamic_ecns|voicecall.speaker'

echo "=== 3. Audioserver service status ==="
getprop init.svc.audioserver

echo "=== 4. Check if KernelSU module is mounted ==="
mount | grep -i 'resourcemanager'

