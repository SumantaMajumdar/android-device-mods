#!/system/bin/sh
MODDIR="/data/adb/modules/qualcomm_aec_fix"

cat << 'EOF' > "$MODDIR/service.sh"
#!/system/bin/sh
sleep 5
TARGET="/vendor/etc/audio/sku_cape/resourcemanager_waipio_mtp.xml"
SRC="/data/adb/modules/qualcomm_aec_fix/system/vendor/etc/audio/sku_cape/resourcemanager_waipio_mtp.xml"
if [ -f "$SRC" ]; then
    mount -o bind "$SRC" "$TARGET"
fi
EOF

chmod 755 "$MODDIR/service.sh"
echo "service.sh installed"

