#!/system/bin/sh
MODDIR=${0%/*}

# Wait until boot is completed before executing late services
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Resolve resetprop binary (works even with su-compat disabled)
RESETPROP=resetprop
if ! command -v resetprop >/dev/null 2>&1; then
    if [ -x /data/adb/ksud ]; then
        RESETPROP="/data/adb/ksud resetprop"
    fi
fi

# ==============================================================================
# 1. MediaTek VoLTE, VoNR & VoWiFi System Properties (Direct Kernel/Init Props)
# ==============================================================================
$RESETPROP -n persist.dbg.volte_avail_ovr 1
$RESETPROP -n persist.dbg.wfc_avail_ovr 1
$RESETPROP -n persist.radio.wfc_avail_ovr 1
$RESETPROP -n persist.vendor.mtk.volte.enable 3
$RESETPROP -n persist.vendor.mtk.vonr.enable 3
$RESETPROP -n persist.vendor.mtk.wfc.enable 3
$RESETPROP -n persist.vendor.mtk_wfc_support 1
$RESETPROP -n persist.vendor.mtk.wfc_support 1
$RESETPROP -n ro.vendor.mtk_wfc_support 1
$RESETPROP -n persist.vendor.volte_support 1
$RESETPROP -n persist.vendor.vowifi_support 1
$RESETPROP -n persist.vendor.radio.volte_state 1
$RESETPROP -n persist.vendor.radio.wfc_state 1
$RESETPROP -n persist.vendor.ims_support 1
$RESETPROP -n persist.vendor.mims_support 2
$RESETPROP -n persist.vendor.dynamic.ims.switch 0
$RESETPROP -n persist.vendor.log.tel_dbg 1

# ==============================================================================
# 2. Android Telephony Provider Database (APN & SIM Provisioning Flags)
# ==============================================================================
DB="/data/user_de/0/com.android.providers.telephony/databases/telephony.db"
if [ -f "$DB" ]; then
    # Ensure Airtel GPRS is dual-stack IPV4V6
    sqlite3 "$DB" "UPDATE carriers SET protocol='IPV4V6', roaming_protocol='IPV4V6' WHERE apn='airtelgprs.com';" 2>/dev/null

    # Ensure Airtel IMS APN is present for all common Airtel circle codes
    for num in 40431 40410 40445 40449 40470 40490 40505 40551 40552 40553 40554; do
        mcc=${num:0:3}
        mnc=${num:3}
        CNT=$(sqlite3 "$DB" "SELECT count(*) FROM carriers WHERE numeric='$num' AND type LIKE '%ims%';" 2>/dev/null)
        if [ "$CNT" = "0" ]; then
            sqlite3 "$DB" "INSERT INTO carriers (name, numeric, mcc, mnc, carrier_id, apn, type, protocol, roaming_protocol, carrier_enabled, bearer_bitmask, user_visible, user_editable) VALUES ('Airtel IMS', '$num', '$mcc', '$mnc', 1961, 'ims', 'ims', 'IPV4V6', 'IPV4V6', 1, 0, 1, 1);" 2>/dev/null
        fi
    done

    # Ensure siminfo provisioning flags are enabled
    sqlite3 "$DB" "UPDATE siminfo SET volte_vt_enabled=1, vt_ims_enabled=1, wfc_ims_enabled=1, wfc_ims_mode=2, wfc_ims_roaming_mode=2, wfc_ims_roaming_enabled=1;" 2>/dev/null
fi

# ==============================================================================
# 3. Android Global Telephony & Wi-Fi Calling Settings
# ==============================================================================
settings put global volte_vt_enabled 1 2>/dev/null
settings put global wfc_ims_enabled 1 2>/dev/null
settings put global wfc_ims_mode 2 2>/dev/null
settings put global wfc_ims_roaming_mode 2 2>/dev/null
settings put global wfc_ims_roaming_enabled 1 2>/dev/null
settings put global enhanced_4g_mode_enabled 1 2>/dev/null

# ==============================================================================
# 4. Enforce Persistent CarrierConfig & IMS Provisioning Cache
# ==============================================================================
CACHE_DIR="/data/user_de/0/com.android.phone/files"
if [ -d "$CACHE_DIR" ]; then
    # Provisioning status
    PROV_FILE="$CACHE_DIR/imsprovisioningstatus_1.xml"
    cat << 'EOF' > "$PROV_FILE"
<bundle>
<pbundle_as_map name="1">
<pbundle_as_map name="0">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
<pbundle_as_map name="1">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
<pbundle_as_map name="3">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
</pbundle_as_map>
<pbundle_as_map name="2">
<pbundle_as_map name="0">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
<pbundle_as_map name="1">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
<pbundle_as_map name="3">
<int name="1" value="1" />
<int name="2" value="1" />
<int name="4" value="1" />
<int name="8" value="1" />
</pbundle_as_map>
</pbundle_as_map>
</bundle>
EOF
    chown radio:radio "$PROV_FILE" 2>/dev/null
    chmod 600 "$PROV_FILE" 2>/dev/null

    # CarrierConfig cache for Airtel (CarrierId 1961)
    for CC_FILE in "$CACHE_DIR"/carrierconfig-com.android.carrierconfig-*-1961.xml; do
        if [ -f "$CC_FILE" ]; then
            chown radio:radio "$CC_FILE" 2>/dev/null
            chmod 600 "$CC_FILE" 2>/dev/null
        fi
    done
fi

# Fallback bind mount CarrierConfig.apk over system_ext if present
if ! mount | grep -q "/system_ext/priv-app/CarrierConfig/CarrierConfig.apk"; then
    if [ -f "$MODDIR/system_ext/priv-app/CarrierConfig/CarrierConfig.apk" ]; then
        mount -o bind "$MODDIR/system_ext/priv-app/CarrierConfig/CarrierConfig.apk" /system_ext/priv-app/CarrierConfig/CarrierConfig.apk 2>/dev/null
        chcon u:object_r:system_file:s0 /system_ext/priv-app/CarrierConfig/CarrierConfig.apk 2>/dev/null
    fi
fi

# ==============================================================================
# 5. Display Hardware Composer (HWC) & MediaTek PQ Optimizations
# ==============================================================================
$RESETPROP -n vendor.debug.hwc.rgbx_scaling 1
$RESETPROP -n vendor.debug.hwc.enable_rpo 1
$RESETPROP -n vendor.debug.hwc.mdp_support_compress 1
$RESETPROP -n vendor.debug.hwc.mdp_support_decompress 1
$RESETPROP -n persist.vendor.debug.hwc.rgbx_scaling 1
$RESETPROP -n persist.vendor.debug.hwc.enable_rpo 1
$RESETPROP -n persist.vendor.debug.hwc.mdp_support_compress 1
$RESETPROP -n persist.vendor.debug.hwc.mdp_support_decompress 1

# Dynamic 60-120Hz refresh rate and window blurs
$RESETPROP -n persist.sys.sf.disable_blurs 0
settings put global disable_window_blurs 0 2>/dev/null
settings put system min_refresh_rate 60.0 2>/dev/null
settings put system peak_refresh_rate 120.0 2>/dev/null

# ==============================================================================
# 6. Unmount Legacy Overlay Bind Mounts & Disable Via Package Manager
# ==============================================================================
# Clear any active bind mounts over /product/overlay to eliminate Inconsistent Mount in detectors
for apk in \
    /product/overlay/GlanceableHubConfigOverlay.apk \
    /product/overlay/GlanceableHubSysuiConfigOverlay.apk \
    /product/overlay/GlanceableHubSettingsConfigOverlay.apk \
    /product/overlay/GlanceableHubSettingsConfigOverlay2022.apk \
    /product/overlay/ColumbusService__infinity_rubyx__auto_generated_rro_product.apk \
    /product/overlay/OmniJaws__infinity_rubyx__auto_generated_rro_product.apk; do
    umount -l "$apk" 2>/dev/null
done

# Disable overlay packages cleanly without any filesystem mounts
for pkg in \
    com.google.android.overlay.glanceablehubconfig \
    com.google.android.systemui.overlay.glanceablehubconfig \
    com.google.android.overlay.glanceablehubsettings \
    com.google.android.overlay.glanceablehubsettings2022 \
    org.protonaosp.columbus.auto_generated_rro_product__ \
    org.omnirom.omnijaws.auto_generated_rro_product__; do
    pm disable "$pkg" 2>/dev/null
    cmd overlay disable "$pkg" 2>/dev/null
done