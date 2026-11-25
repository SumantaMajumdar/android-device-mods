# VoWiFi (Wi-Fi Calling) Handoff & Architecture Guide

## Devices Covered
1. **Xiaomi Redmi Note 10S** (`rosemary` / `secret` — MediaTek Helio G95 / MT6785)
2. **Xiaomi Redmi Note 12 Pro 5G / Pro+** (`ruby` / `rubyx` — MediaTek Dimensity 1080 / MT6877)

---

## 1. Executive Summary & Deliverables

This document summarizes the root cause analysis, architecture, carrier constraints (Airtel, Jio, BSNL), and the finalized root-level modules (Magisk / KernelSU / APatch) developed to permanently restore native **VoWiFi (Voice-over-Wi-Fi / Wi-Fi Calling)** on custom AOSP/LineageOS-based ROMs.

### Deliverables in Workspace
| Target Device | Chipset | Flashable Zip Module | Unpacked Source Directory |
| :--- | :--- | :--- | :--- |
| **Redmi Note 10S** (`rosemary`) | MediaTek Helio G95 (MT6785) | `Rosemary_VoWiFi_Fix.zip` | `Rosemary_VoWiFi_Fix_Module/` |
| **Redmi Note 12 Pro 5G** (`ruby`) | MediaTek Dimensity 1080 (MT6877) | `Airtel_VoWiFi_Fix_Ruby.zip` | `Ruby_VoWiFi_Fix_Module/` |

---

## 2. MediaTek VoWiFi & IMS Architecture

MediaTek devices utilize a hybrid proprietary stack to manage Voice over LTE (VoLTE) and Voice over Wi-Fi (VoWiFi):

```
┌────────────────────────────────────────────────────────┐
│                   Android Telephony Framework          │
│   (TelephonyManager / ImsManager / CarrierConfig)     │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│      Vendor IMS Services & Entitlement Daemons         │
│   (ImsService.apk / com.android.imsserviceentitlement) │
└─────────────┬───────────────────────────┬──────────────┘
              │                           │
              ▼                           ▼
┌───────────────────────────┐   ┌────────────────────────┐
│   MediaTek WOD Daemon     │   │   mtkfusionrild (RIL)  │
│   (/vendor/bin/epdg_wod)  │   │  (/vendor/bin/hw/...)  │
│   (/vendor/lib64/libwo.so)│   └───────────┬────────────┘
└─────────────┬─────────────┘               │
              │ IPsec Tunnel (IR.51)        │ AT / CCCI commands
              ▼                             ▼
┌───────────────────────────┐   ┌────────────────────────┐
│   Wi-Fi Interface (wlan0) │   │ Cellular Modems (ccmni)│
│  ePDG Gateway via 3GPP    │   │ ccmni0 = Data Default  │
│  (DNS: epdg.epc.mnc...)   │   │ ccmni1 = IMS Bearer    │
└───────────────────────────┴───┴────────────────────────┘
```

1. **Dual Cellular Bearers (ccmni interfaces):**
   * `ccmni0`: Primary packet-data network (PDN) for standard mobile data.
   * `ccmni1`: Dedicated IMS PDN for SIP signaling and RTP audio.
2. **ePDG Handover Daemon (`epdg_wod` & `libwo.so`):**
   * The Wi-Fi Offload Daemon (`wod`) negotiates IKEv2 / IPsec tunnels with the carrier’s **evolved Packet Data Gateway (ePDG)**.
   * When Wi-Fi quality meets thresholds, `wod` initiates handover from `ccmni1` to the IPsec tunnel on `wlan0`.
3. **CarrierConfig & Entitlement:**
   * Carrier-specific SIM profiles (`40445` / `40431` for Airtel India) determine if VoWiFi is enabled, whether entitlement checks can be bypassed (`skip_wfc_activation_bool`), and preferred calling modes.

---

## 3. Device 1: Redmi Note 10S (`rosemary`)

### Root Cause on Custom ROMs
* Custom AOSP trees for `rosemary` omitted proprietary MediaTek vendor binaries (`/vendor/bin/epdg_wod` and `/vendor/lib64/libwo.so`).
* `/vendor/etc/init/init.wod.rc` failed to execute because SELinux denied socket operations and capabilities.
* Missing `mtkimsprobe.dex` prevented the framework from probing modem IMS capabilities.

### Solution Architecture (`Rosemary_VoWiFi_Fix.zip`)
* **Binary Overlays:**
  * Injects 64-bit `epdg_wod` into `/system/vendor/bin/epdg_wod`.
  * Injects `libwo.so` into `/system/vendor/lib64/libwo.so`.
  * Restores `mtkimsprobe.dex` in `/system/system_ext/etc/mtkimsprobe.dex`.
* **Init & RC Services:**
  * Restores `init.wod.rc` and `init.wfc-capability-override.rc` to spawn `wod` as a background service.
* **SELinux Policies (`sepolicy.rule`):**
  * Grants `wod` domain permissions to bind sockets, manipulate network interfaces, and talk to `mtkfusionrild`.
* **System Telephony Properties (`service.sh`):**
  ```bash
  setprop persist.vendor.mims_support 2
  setprop persist.vendor.volte_support 1
  setprop persist.vendor.vowifi_support 1
  setprop persist.vendor.vilte_support 1
  setprop persist.vendor.mtk.volte.enable 1
  setprop persist.vendor.mtk_vowifi_support 1
  ```

---

## 4. Device 2: Redmi Note 12 Pro 5G / Pro+ (`ruby` / `rubyx`)

### Root Cause on Custom ROMs (e.g., Project Infinity-X / LineageOS)
1. **Mobile Data Suspended on Wi-Fi:**
   * Custom ROMs defaulted `mobile_data_always_on = 0`.
   * When connected to Wi-Fi, the modem severed `ccmni1` with `LOST_CONNECTION(0x10004)`, completely killing the IMS registration before an ePDG IPsec tunnel could establish.
2. **Aggressive Doze / LMK Freezer:**
   * Android power management placed `com.android.imsserviceentitlement` and `com.mediatek.ims` into the kernel cgroup freezer and subsequently killed them during idle standby.
3. **CarrierConfig Flags Missing:**
   * Airtel India SIM profile was missing `skip_wfc_activation_bool = true`, causing the OS to wait indefinitely for carrier server entitlement tokens that Airtel does not serve over non-stock ROMs.

### Solution Architecture (`Airtel_VoWiFi_Fix_Ruby.zip`)
* **Patched CarrierConfig (`CarrierConfig.apk` overlay):**
  * Overlays `/system/system_ext/priv-app/CarrierConfig/CarrierConfig.apk` with modified carrier configs:
    * `carrier_wfc_ims_available_bool = true`
    * `carrier_wfc_supports_wifi_only_bool = true`
    * `wfc_emergency_address_carrier_quality_supported_bool = false`
    * `skip_wfc_activation_bool = true`
* **Automated Runtime Tuning (`service.sh`):**
  * Whitelists critical IMS packages from Doze/battery optimization:
    ```bash
    dumpsys deviceidle whitelist +com.mediatek.ims
    dumpsys deviceidle whitelist +com.android.imsserviceentitlement
    dumpsys deviceidle whitelist +com.android.phone
    ```
  * Enforces continuous mobile bearer connectivity:
    ```bash
    settings put global mobile_data_always_on 1
    ```
  * Ensures static IMS parameters are bound:
    ```bash
    setprop persist.vendor.ims.support 1
    setprop persist.vendor.mims_support 2
    setprop persist.vendor.wfc.support 1
    setprop persist.vendor.mtk_vowifi_support 1
    ```

---

## 5. Carrier Realities & Findings (Airtel vs. Jio vs. BSNL)

| Carrier | VoLTE Support | Native 3GPP VoWiFi Support | ePDG Gateway FQDN | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Airtel India** | Yes | **Full Support** | `epdg.epc.mnc045.mcc404.pub.3gppnetwork.org` | Requires `skip_wfc_activation_bool=true` and dual-stack IPv4/IPv6 `ims` APN. |
| **Reliance Jio** | Yes | **Full Support** | `epdg.epc.mnc861.mcc405.pub.3gppnetwork.org` | Standard IMS bearer, auto-provisions immediately. |
| **BSNL** | Partial (Circle dependent) | **No Native 3GPP VoWiFi** | *None deployed* | BSNL does **not** have operational 3GPP ePDG infrastructure. Native VoWiFi will not register; BSNL requires their standalone VoIP app ("BSNL Wings" SIP app). |

---

## 6. Installation & Verification Guide

### Step 1: Flashing the Module
1. Copy the appropriate zip file to the device storage:
   * Redmi Note 10S: `Rosemary_VoWiFi_Fix.zip`
   * Redmi Note 12 Pro: `Airtel_VoWiFi_Fix_Ruby.zip`
2. Open **Magisk**, **KernelSU**, or **APatch**.
3. Go to **Modules** -> **Install from storage** -> Select the `.zip` file.
4. Reboot the device.

### Step 2: Verification via ADB / Terminal
Run the following commands to confirm full VoWiFi registration:

```bash
# 1. Check IMS Registration status
dumpsys telephony.registry | grep -E "mServiceState|isOnWfc|isImsRegistered"

# Expected output:
#   isImsRegistered=true
#   isOnWfc=true

# 2. Check Whitelist Status (DeviceIdle)
dumpsys deviceidle whitelist | grep -E "mediatek|entitlement"

# 3. Verify MediaTek VoWiFi properties
getprop | grep -E "vowifi|wfc"
```

### Step 3: UI Verification
* In **Settings -> Network & Internet -> SIMs -> Airtel/Jio**:
  * **Wi-Fi Calling** toggle is visible and ON.
  * Calling preference can be set to **Call over Wi-Fi**.
* Status bar will display the **VoWiFi** icon next to the Wi-Fi signal indicator.

