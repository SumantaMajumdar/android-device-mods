umount /product/overlay/NavigationBarModeGestural/NavigationBarModeGesturalOverlay.apk 2>/dev/null || true
APK="/data/adb/modules/nokeyboardgap/NavigationBarModeGesturalOverlay.apk"
chmod 644 "$APK"
chown root:root "$APK"
chcon u:object_r:system_file:s0 "$APK"

# Remove the broken idmap so idmap2d generates a fresh one
rm -f /data/resource-cache/product@overlay@NavigationBarModeGestural@NavigationBarModeGesturalOverlay.apk@idmap

mount -o bind "$APK" /product/overlay/NavigationBarModeGestural/NavigationBarModeGesturalOverlay.apk

# Tell OverlayManagerService to re-evaluate
cmd overlay disable com.android.internal.systemui.navbar.gestural
cmd overlay enable com.android.internal.systemui.navbar.gestural

sleep 1
cmd overlay dump com.android.internal.systemui.navbar.gestural | head -n 15

