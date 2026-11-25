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
$RESETPROP -n persist.vendor.dynamic.ims.switch 1
$RESETPROP -n persist.vendor.mtk.dynamic_ims_switch 1
$RESETPROP -n persist.vendor.mtk_dynamic_ims_switch 1
$RESETPROP -n persist.vendor.log.tel_dbg 0

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

    # Ensure active SIM numeric has an IMS APN (BSNL, Jio, Vi, etc.)
    SIM_NUM=$(getprop gsm.sim.operator.numeric | tr -d ' ' | cut -d',' -f1)
    if [ -n "$SIM_NUM" ]; then
        CNT=$(sqlite3 "$DB" "SELECT count(*) FROM carriers WHERE numeric='$SIM_NUM' AND type LIKE '%ims%';" 2>/dev/null)
        if [ "$CNT" = "0" ]; then
            mcc=${SIM_NUM:0:3}
            mnc=${SIM_NUM:3}
            sqlite3 "$DB" "INSERT INTO carriers (name, numeric, mcc, mnc, carrier_id, apn, type, protocol, roaming_protocol, carrier_enabled, bearer_bitmask, user_visible, user_editable) VALUES ('IMS APN', '$SIM_NUM', '$mcc', '$mnc', 0, 'ims', 'ims', 'IPV4V6', 'IPV4V6', 1, 0, 1, 1);" 2>/dev/null
        fi
    fi

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
settings put global volte_subscription0 1 2>/dev/null
settings put global volte_subscription1 1 2>/dev/null
settings put global restricted_networking_mode 0 2>/dev/null

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

    # Inject VoWiFi and VoLTE flags into all active CarrierConfig cache files
    for CC_FILE in "$CACHE_DIR"/carrierconfig-com.android.carrierconfig-*.xml; do
        if [ -f "$CC_FILE" ]; then
            cat << 'EOF' > "$CC_FILE"
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<bundle>
<int name="httpSocketTimeout" value="300000" />
<string name="__carrier_config_package_version__">1</string>
<boolean name="carrier_volte_available_bool" value="true" />
<boolean name="carrier_volte_provisioned_bool" value="true" />
<boolean name="carrier_volte_provisioning_required_bool" value="false" />
<boolean name="carrier_wfc_ims_available_bool" value="true" />
<boolean name="carrier_default_wfc_ims_enabled_bool" value="true" />
<int name="carrier_default_wfc_ims_mode_int" value="2" />
<boolean name="carrier_default_wfc_ims_roaming_enabled_bool" value="true" />
<int name="carrier_default_wfc_ims_roaming_mode_int" value="2" />
<boolean name="carrier_wfc_supports_wifi_only_bool" value="false" />
<boolean name="editable_wfc_mode_bool" value="true" />
<boolean name="editable_wfc_roaming_mode_bool" value="true" />
<boolean name="enhanced_4g_lte_on_by_default_bool" value="true" />
<boolean name="editable_enhanced_4g_lte_bool" value="true" />
<boolean name="hide_enhanced_4g_lte_bool" value="false" />
<boolean name="imsserviceentitlement.skip_wfc_activation_bool" value="true" />
<boolean name="use_default_ims_apn_when_absent_bool" value="true" />
<boolean name="show_wfc_icon_in_status_bar_bool" value="true" />
<boolean name="show_4g_for_lte_data_icon_bool" value="true" />
<boolean name="carrier_allow_turnoff_ims_bool" value="true" />
<boolean name="handover_of_ims_calls_between_wifi_and_cellular_allowed_bool" value="true" />
<boolean name="carrier_data_call_retry_network_provided_bool" value="true" />
<boolean name="carrier_promote_wfc_on_call_fail_bool" value="true" />
<string-array name="iwlan_handover_policy_string_array" num="1">
<item value="source=GERAN|UTRAN|EUTRAN|NGRAN|IWLAN, target=GERAN|UTRAN|EUTRAN|NGRAN|IWLAN, type=allowed" />
</string-array>
<string-array name="telephony_data_handover_retry_rules_string_array" num="1">
<item value="retry_interval=1000|2000|4000|8000|16000, maximum_retries=5" />
</string-array>
<string-array name="carrier_certificate_string_array" num="3">
<item value="7170F9C35AC5966C1687372089AF55713DACC17635BAD248370DA67DDF8472B6:com.myairtelapp" />
<item value="FB9FD5425AB63FA933CF8125B2F3EFC0DF11F0DE0C9C01EF2F2B71A3EBD135A3:com.airtelx.airtelkiosk" />
<item value="A9AC70C78969FE7B7EA742AEADE2C5F93CE8E83FB7314F67572F67178CF0C102:com.airtelx.airtelknoxguard" />
</string-array>
<string-array name="roaming_operator_string_array" num="2">
<item value="404" />
<item value="405" />
</string-array>
<string name="carrier_name_string">airtel</string>
<boolean name="carrier_name_override_bool" value="true" />
</bundle>
EOF
            chown radio:radio "$CC_FILE" 2>/dev/null
            chmod 600 "$CC_FILE" 2>/dev/null
            chattr +i "$CC_FILE" 2>/dev/null
        fi
    done
    chattr +i "$PROV_FILE" 2>/dev/null
fi

# Execute MtkImsProbe to register WFC capability with MTK IMS
if [ -f /system_ext/etc/mtkimsprobe.dex ]; then
    app_process -Djava.class.path=/system_ext/etc/mtkimsprobe.dex /system/bin MtkImsProbe enable-cache 2>/dev/null
elif [ -f "$MODDIR/system/system_ext/etc/mtkimsprobe.dex" ]; then
    app_process -Djava.class.path="$MODDIR/system/system_ext/etc/mtkimsprobe.dex" /system/bin MtkImsProbe enable-cache 2>/dev/null
fi

# Ensure IPsec starter / charon is running
if ! pgrep charon >/dev/null 2>&1; then
    /vendor/bin/starter --daemon charon 2>/dev/null
fi

# Ensure epdg_wod is started
if [ "$(getprop init.svc.vendor.epdg_wod)" != "running" ]; then
    start vendor.epdg_wod 2>/dev/null
fi

# Unmount any legacy CarrierConfig bind mount if leftover
umount -l /system_ext/priv-app/CarrierConfig/CarrierConfig.apk 2>/dev/null

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

# ==============================================================================
# 7. Standby Battery & Connectivity Persistence
# ==============================================================================
settings put global mobile_data_always_on 1 2>/dev/null
settings put global mobile_data 1 2>/dev/null
settings put global mobile_data1 1 2>/dev/null
settings put global wifi_scan_always_enabled 0 2>/dev/null
settings put global ble_scan_always_enabled 0 2>/dev/null
settings put global adaptive_battery_management_enabled 1 2>/dev/null
settings delete global deviceidle_constants 2>/dev/null
dumpsys deviceidle whitelist +com.mediatek.ims 2>/dev/null
dumpsys deviceidle whitelist +com.android.imsserviceentitlement 2>/dev/null
dumpsys deviceidle whitelist +com.android.phone 2>/dev/null
am set-standby-bucket com.android.imsserviceentitlement active 2>/dev/null
