import subprocess
import time

def adb(cmd):
    p = subprocess.run(['adb', 'shell', cmd], capture_output=True, text=True)
    return p.stdout + p.stderr

print("Setting verbose tags...")
tags = [
    "persist.log.tag.MtkImsService",
    "persist.log.tag.MtkImsManager",
    "persist.log.tag.ImsService",
    "persist.log.tag.WfcHandler",
    "persist.log.tag.WifiPdnHandler",
    "persist.log.tag.RtcMwi",
    "persist.log.tag.RmcMwi",
    "persist.log.tag.ImsApp",
    "persist.log.tag.RmcImsCtlReqHdl",
    "persist.log.tag.RmcImsCtlUrcHdl",
    "persist.log.tag.RtcIms"
]
for t in tags:
    adb(f"/data/adb/ksud resetprop {t} V")

# Also check provision prop
print("Current provision:", adb("getprop persist.vendor.mtk.provision.int.01"))
adb("/data/adb/ksud resetprop persist.vendor.mtk.provision.int.01 '26,1;27,1;66,0;'")
adb("/data/adb/ksud resetprop persist.vendor.mtk.provision.int.11 '26,1;27,1;66,0;'")

print("Clearing logcat...")
adb("logcat -c")

print("Restarting com.mediatek.ims...")
adb("pkill -9 -f com.mediatek.ims")

time.sleep(3)

print("Recent logs from logcat:")
log = subprocess.run(['adb', 'logcat', '-d', '-t', '150'], capture_output=True, text=True).stdout
for line in log.splitlines():
    print(line)
