# Android Device Mods & Root Modules

A curated repository of root-level (Magisk, KernelSU, APatch) modules, hardware fixes, and system optimization scripts for Android custom ROMs (AOSP / LineageOS).

---

## Repository Structure

```
├── vowifi-fixes/
│   ├── modules/
│   │   ├── rosemary-vowifi-fix/       # Redmi Note 10S (MediaTek Helio G95 / MT6785) VoWiFi fix
│   │   └── ruby-vowifi-fix/           # Redmi Note 12 Pro 5G (Dimensity 1080 / MT6877) VoWiFi fix
│   ├── flashable-zips/                # Ready-to-flash Magisk / KernelSU module zips
│   ├── docs/                          # Comprehensive VoWiFi & ePDG architecture documentation
│   └── tools/                         # Automated diagnostic and IMS verification scripts
│
├── qualcomm-aec-echo-fix/
│   ├── resourcemanager_waipio_mtp.xml # Qualcomm audio calibration XML restoring ext_ec_ref_enabled
│   ├── apply_aec_fix.sh               # Live runtime bind-mount script for testing
│   ├── install_module_service.sh      # Service script for persistent boot mounting
│   └── verify_audio.sh                # Diagnostic script to verify AEC active status
│
├── navbar-and-keyboard-mods/
│   ├── apply_no_keyboard_gap.sh       # RRO overlay fabricator to remove blank space below keyboards
│   └── fix_selinux_overlay.sh         # SELinux and idmap fixes for custom navbar overlays
│
└── telephony-debloat/
    └── disable_telephony.sh           # Safe debloat script for Wi-Fi-only tablets (e.g. Lenovo Legion Y700)
```

---

## Detailed Component Summaries

### 1. MediaTek VoWiFi & WOD Fixes (`vowifi-fixes/`)
* **Redmi Note 10S (`rosemary` / `secret` - MT6785):**
  * Solves missing MediaTek vendor binaries (`epdg_wod`, `libwo.so`) on custom AOSP trees.
  * Restores `mtkimsprobe.dex`, WOD init services, and sepolicy rules for IPsec IKEv2 tunnel establishment with carrier ePDG.
  * Injects persistent `CarrierConfig` overrides (`skip_wfc_activation_bool = true`, etc.).
* **Redmi Note 12 Pro 5G / Pro+ (`ruby` / `rubyx` - MT6877):**
  * Fixes aggressive modem packet detachment when switching between Wi-Fi and mobile data.
  * Prevents system freezer / Doze from terminating `com.android.imsserviceentitlement` and `com.mediatek.ims`.
  * Configures carrier-specific IMS parameters for Airtel India, Jio, and BSNL.

### 2. Qualcomm AEC Hardware Echo-Cancellation (`qualcomm-aec-echo-fix/`)
* **Target:** Qualcomm Snapdragon 8+ Gen 1 (SM8475 / Waipio / Cape) running custom ROMs (e.g., Lenovo Legion Tab Y700).
* **Problem:** Speaker echo on loudspeaker VoIP calls (WhatsApp, Telegram) because custom ROM vendor trees fail to feed the speaker audio reference channel back into the Qualcomm DSP acoustic echo cancellation (ECNS) filter.
* **Fix:** Patches `resourcemanager_waipio_mtp.xml` to enable `ext_ec_ref_enabled = 1` across `speaker-mic` and `handset-mic` use cases, binding the speaker feedback stream to the DSP AEC pipeline.

### 3. Bottom Keyboard Gap Removal (`navbar-and-keyboard-mods/`)
* **Target:** Android 10+ / 14 / 15 gesture navigation.
* **Problem:** Empty bar / gap rendered below third-party keyboards (HeliBoard, Gboard) when using gesture navigation.
* **Fix:** Leverages Android's built-in Runtime Resource Overlay (RRO) fabrication mechanism (`config_imeDrawsImeNavBar = false`) via `com.android.shell:NoImeBar` to cleanly eliminate keyboard padding without breaking system gesture navigation.

### 4. Telephony Debloat for Wi-Fi-Only Tablets (`telephony-debloat/`)
* **Target:** Wi-Fi only tablets running custom ROMs ported from smartphone trees.
* **Fix:** Safely disables dormant cellular services (`com.android.phone`, `com.android.providers.telephony`, `com.android.mms.service`, `com.android.smspush`, and `com.android.simappdialog`) while preserving `com.android.server.telecom` so VoIP calling remains fully functional.

---

## License
MIT License. Open-source contribution for the Android custom ROM community.
