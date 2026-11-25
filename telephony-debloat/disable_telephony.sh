#!/system/bin/sh
# Disables dormant telephony, MMS, SMS push, and SIM dialog services
# Designed for Wi-Fi-only tablets (such as Lenovo Legion Tab Y700)
# Preserves TelecomManager to keep VoIP calls (WhatsApp, etc.) working properly.

echo "Disabling cellular and telephony background services..."
pm disable-user --user 0 com.android.phone
pm disable-user --user 0 com.android.providers.telephony
pm disable-user --user 0 com.android.mms.service
pm disable-user --user 0 com.android.smspush
pm disable-user --user 0 com.android.simappdialog

echo "Done! Current disabled telephony packages:"
pm list packages -d | grep -iE 'phone|telephony|mms|sms|sim'
