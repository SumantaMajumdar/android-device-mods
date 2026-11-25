#!/system/bin/sh
echo "=== Fabricating individual overlays ==="

# 1. Disable IME drawing the navbar (the main bar under keyboard)
cmd overlay fabricate --target android --name NoImeBar android:bool/config_imeDrawsImeNavBar 0x12 0x0
cmd overlay enable --user current com.android.shell:NoImeBar

echo "=== Verifying values ==="
echo "config_imeDrawsImeNavBar:"
cmd overlay lookup android android:bool/config_imeDrawsImeNavBar

# Ensure it's in service.sh of nokeyboardgap module so it persists across boots
SERVICE_SH="/data/adb/modules/nokeyboardgap/service.sh"
if [ -f "$SERVICE_SH" ]; then
    sed -i '/NoImeBar/d' "$SERVICE_SH"
    cat << 'EOF' >> "$SERVICE_SH"

# Remove keyboard bottom bar gap
cmd overlay fabricate --target android --name NoImeBar android:bool/config_imeDrawsImeNavBar 0x12 0x0
cmd overlay enable --user current com.android.shell:NoImeBar
EOF
fi

echo "Done! Active overlay status:"
cmd overlay list | grep -i NoImeBar
