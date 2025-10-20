#!/bin/bash

# Auto DNS Switcher für macOS
# Wechselt automatisch zwischen Adguard DNS (Heimnetz) und DHCP DNS (Hotspot)

# Konfiguration
HOME_NETWORK_SSID="DEIN_HEIMNETZ_SSID"  # <-- HIER DEINE HEIMNETZ SSID EINTRAGEN
ADGUARD_DNS="192.168.128.253"
NETWORK_SERVICE="Wi-Fi"

# Logging
LOG_FILE="/var/log/auto-dns-switch.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# WiFi-Interface ermitteln (en0, en1, etc.)
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

# Aktuell verbundenes WLAN ermitteln (kompatibel mit modernem macOS)
if [ -n "$WIFI_DEVICE" ]; then
    current_ssid=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null | awk -F': ' '{print $2}')
else
    log_message "FEHLER: Kein WiFi-Interface gefunden"
    exit 1
fi

log_message "Script gestartet. Aktuelles SSID: $current_ssid"

# DNS-Server abrufen
current_dns=$(networksetup -getdnsservers "$NETWORK_SERVICE" | head -n 1)

if [ "$current_ssid" == "$HOME_NETWORK_SSID" ]; then
    # Im Heimnetz: Adguard DNS setzen
    if [ "$current_dns" != "$ADGUARD_DNS" ]; then
        log_message "Heimnetz erkannt. Setze Adguard DNS: $ADGUARD_DNS"
        networksetup -setdnsservers "$NETWORK_SERVICE" "$ADGUARD_DNS" 192.168.128.254 1.1.1.1
        log_message "DNS erfolgreich auf Adguard umgestellt"
    else
        log_message "Heimnetz erkannt. DNS bereits korrekt konfiguriert"
    fi
elif [ -n "$current_ssid" ]; then
    # Anderes Netzwerk (Hotspot): Automatischen DNS (DHCP)
    if [ "$current_dns" == "$ADGUARD_DNS" ] || [ "$current_dns" == "There aren't any DNS Servers set on $NETWORK_SERVICE." ]; then
        log_message "Externes Netzwerk erkannt ($current_ssid). Setze automatischen DNS"
        networksetup -setdnsservers "$NETWORK_SERVICE" "Empty"
        log_message "DNS erfolgreich auf automatisch (DHCP) umgestellt"
    else
        log_message "Externes Netzwerk erkannt. DNS bereits auf automatisch"
    fi
else
    log_message "Kein WLAN verbunden"
fi

log_message "Script beendet"
