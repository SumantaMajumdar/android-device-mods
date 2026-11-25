import subprocess
import time

def adb(cmd):
    p = subprocess.run(['adb', 'shell', cmd], capture_output=True, text=True)
    return p.stdout.strip()

print("Applying fix...")
adb("/data/adb/ksud resetprop -n persist.vendor.mtk.dynamic_ims_switch 1")
adb("/data/adb/ksud resetprop -n persist.vendor.dynamic.ims.switch 1")
adb("/data/adb/ksud resetprop -n persist.vendor.mtk_dynamic_ims_switch 1")
adb("settings put global volte_subscription0 1")
adb("settings put global volte_subscription1 1")
adb("settings put global restricted_networking_mode 0")
adb("am set-standby-bucket com.android.imsserviceentitlement active 2>/dev/null")

print("Restarting com.mediatek.ims...")
adb("pkill -9 -f com.mediatek.ims")
time.sleep(3)

print("Toggling radio power...")
adb("cmd phone set-radio-power false")
time.sleep(2)
adb("cmd phone set-radio-power true")
time.sleep(6)

print("=== Results ===")
print("pdn.info:", adb("getprop vendor.ims.eims.pdn.info"))
print("ccmni1 status:", adb("ip a show ccmni1"))
print("telephony.registry disconnect cause & data:")
reg = adb("dumpsys telephony.registry")
for line in reg.splitlines():
    if any(k in line for k in ['mImsCallDisconnectCause', 'mPreciseDataConnectionStates', 'isImsRegistered']):
        print(line)
