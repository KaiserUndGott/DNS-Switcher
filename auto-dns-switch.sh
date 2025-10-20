#!/bin/bash

# Auto DNS Switcher für macOS 26+
# Wechselt automatisch zwischen Adguard DNS (Heimnetz) und DHCP DNS (Hotspot)
# Kompatibel mit macOS Sequoia (26.x) und höher

# Konfigurationsdatei
CONFIG_FILE="/usr/local/etc/auto-dns-switch.conf"

# Standard-Konfiguration
HOME_NETWORK_SSID="DEIN_HEIMNETZ_SSID"
HOTSPOT_SSID="DEIN_HOTSPOT_SSID"
ADGUARD_DNS="192.168.128.253"
NETWORK_SERVICE="Wi-Fi"

# Logging
LOG_FILE="/var/log/auto-dns-switch.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Konfiguration laden, falls vorhanden
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# WiFi-Interface ermitteln (en0, en1, etc.)
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

if [ -z "$WIFI_DEVICE" ]; then
    log_message "FEHLER: Kein WiFi-Interface gefunden"
    exit 1
fi

# Aktuell verbundenes WLAN ermitteln (kompatibel mit macOS 26+)
current_ssid=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null | awk -F': ' '{print $2}')

# Prüfen ob "You are not associated" zurückgegeben wurde
if [[ "$current_ssid" == *"not associated"* ]] || [ -z "$current_ssid" ]; then
    log_message "Script gestartet. Kein WLAN verbunden"
    exit 0
fi

log_message "Script gestartet. Aktuelles SSID: '$current_ssid'"

# DNS-Server abrufen
current_dns=$(networksetup -getdnsservers "$NETWORK_SERVICE" | head -n 1)

# Entscheidungslogik basierend auf SSID
if [ "$current_ssid" == "$HOME_NETWORK_SSID" ]; then
    # Im Heimnetz: Adguard DNS setzen
    if [ "$current_dns" != "$ADGUARD_DNS" ]; then
        log_message "Heimnetz '$HOME_NETWORK_SSID' erkannt. Setze Adguard DNS: $ADGUARD_DNS"
        networksetup -setdnsservers "$NETWORK_SERVICE" "$ADGUARD_DNS" 192.168.128.254 1.1.1.1
        log_message "DNS erfolgreich auf Adguard umgestellt"
    else
        log_message "Heimnetz erkannt. DNS bereits korrekt konfiguriert"
    fi

elif [ "$current_ssid" == "$HOTSPOT_SSID" ]; then
    # Hotspot erkannt: Automatischen DNS (DHCP)
    if [ "$current_dns" == "$ADGUARD_DNS" ] || [ "$current_dns" == "There aren't any DNS Servers set on $NETWORK_SERVICE." ]; then
        log_message "Hotspot '$HOTSPOT_SSID' erkannt. Setze automatischen DNS (DHCP)"
        networksetup -setdnsservers "$NETWORK_SERVICE" "Empty"
        log_message "DNS erfolgreich auf automatisch (DHCP) umgestellt"
    else
        log_message "Hotspot erkannt. DNS bereits auf automatisch"
    fi

elif [ "$HOTSPOT_SSID" == "DEIN_HOTSPOT_SSID" ]; then
    # Hotspot-SSID wurde noch nicht konfiguriert
    log_message "WARNUNG: Unbekanntes WLAN '$current_ssid' - Hotspot-SSID nicht konfiguriert"
    log_message "Bitte Hotspot-SSID in $CONFIG_FILE konfigurieren"

    # Prüfen ob dies ein neuer Hotspot sein könnte
    if [ "$current_ssid" != "$HOME_NETWORK_SSID" ]; then
        log_message "HINWEIS: Ist '$current_ssid' dein Hotspot? Falls ja, führe aus:"
        log_message "  sudo /usr/local/bin/auto-dns-switch-config.sh"

        # Setze automatischen DNS als Fallback
        networksetup -setdnsservers "$NETWORK_SERVICE" "Empty"
        log_message "Fallback: DNS auf automatisch (DHCP) gesetzt"
    fi

else
    # Unbekanntes Netzwerk - könnte geänderter Hotspot sein
    log_message "WARNUNG: Unbekanntes WLAN '$current_ssid' erkannt"
    log_message "Bekannte Netzwerke: Heimnetz='$HOME_NETWORK_SSID', Hotspot='$HOTSPOT_SSID'"
    log_message "HINWEIS: Falls dies dein neuer Hotspot ist, führe aus:"
    log_message "  sudo /usr/local/bin/auto-dns-switch-config.sh"

    # Setze automatischen DNS als Fallback für unbekannte Netze
    if [ "$current_dns" == "$ADGUARD_DNS" ]; then
        log_message "Setze automatischen DNS (DHCP) für unbekanntes Netzwerk"
        networksetup -setdnsservers "$NETWORK_SERVICE" "Empty"
        log_message "DNS erfolgreich auf automatisch (DHCP) umgestellt"
    else
        log_message "DNS bereits auf automatisch oder DHCP"
    fi
fi

log_message "Script beendet"
