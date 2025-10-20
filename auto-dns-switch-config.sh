#!/bin/bash

# Konfigurationstool für Auto DNS Switcher
# Ermöglicht die Aktualisierung der SSIDs (Heimnetz und Hotspot)

CONFIG_FILE="/usr/local/etc/auto-dns-switch.conf"
LOG_FILE="/var/log/auto-dns-switch.log"

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "FEHLER: Dieses Script muss mit sudo ausgeführt werden!"
    echo "Bitte ausführen: sudo /usr/local/bin/auto-dns-switch-config.sh"
    exit 1
fi

echo "=== Auto DNS Switcher - Konfiguration ==="
echo ""

# Aktuelle Konfiguration laden, falls vorhanden
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Aktuelle Konfiguration:"
    echo "  Heimnetz SSID:  $HOME_NETWORK_SSID"
    echo "  Hotspot SSID:   $HOTSPOT_SSID"
    echo "  Adguard DNS:    $ADGUARD_DNS"
    echo ""
else
    HOME_NETWORK_SSID="DEIN_HEIMNETZ_SSID"
    HOTSPOT_SSID="DEIN_HOTSPOT_SSID"
    ADGUARD_DNS="192.168.128.253"
fi

# WiFi-Interface ermitteln
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
current_ssid=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null | awk -F': ' '{print $2}')

if [[ "$current_ssid" != *"not associated"* ]] && [ -n "$current_ssid" ]; then
    echo "Aktuell verbundenes WLAN: '$current_ssid'"
    echo ""
fi

# Menü
echo "Was möchtest du konfigurieren?"
echo "  1) Heimnetz SSID"
echo "  2) Hotspot SSID"
echo "  3) Beide SSIDs"
echo "  4) Adguard DNS-IP"
echo "  5) Konfiguration anzeigen"
echo "  0) Abbrechen"
echo ""
read -p "Auswahl: " choice

case $choice in
    1)
        read -p "Neue Heimnetz SSID: " new_home_ssid
        if [ -n "$new_home_ssid" ]; then
            HOME_NETWORK_SSID="$new_home_ssid"
            echo "✓ Heimnetz SSID aktualisiert: $HOME_NETWORK_SSID"
        fi
        ;;
    2)
        read -p "Neue Hotspot SSID: " new_hotspot_ssid
        if [ -n "$new_hotspot_ssid" ]; then
            HOTSPOT_SSID="$new_hotspot_ssid"
            echo "✓ Hotspot SSID aktualisiert: $HOTSPOT_SSID"
        fi
        ;;
    3)
        read -p "Neue Heimnetz SSID: " new_home_ssid
        read -p "Neue Hotspot SSID: " new_hotspot_ssid
        if [ -n "$new_home_ssid" ]; then
            HOME_NETWORK_SSID="$new_home_ssid"
            echo "✓ Heimnetz SSID aktualisiert: $HOME_NETWORK_SSID"
        fi
        if [ -n "$new_hotspot_ssid" ]; then
            HOTSPOT_SSID="$new_hotspot_ssid"
            echo "✓ Hotspot SSID aktualisiert: $HOTSPOT_SSID"
        fi
        ;;
    4)
        read -p "Neue Adguard DNS-IP: " new_dns
        if [ -n "$new_dns" ]; then
            ADGUARD_DNS="$new_dns"
            echo "✓ Adguard DNS aktualisiert: $ADGUARD_DNS"
        fi
        ;;
    5)
        echo ""
        echo "Aktuelle Konfiguration:"
        echo "  Heimnetz SSID:  $HOME_NETWORK_SSID"
        echo "  Hotspot SSID:   $HOTSPOT_SSID"
        echo "  Adguard DNS:    $ADGUARD_DNS"
        echo ""
        exit 0
        ;;
    0)
        echo "Abgebrochen."
        exit 0
        ;;
    *)
        echo "Ungültige Auswahl."
        exit 1
        ;;
esac

# Konfiguration speichern
mkdir -p /usr/local/etc
cat > "$CONFIG_FILE" <<EOF
# Auto DNS Switcher Konfiguration
# Erstellt: $(date '+%Y-%m-%d %H:%M:%S')

HOME_NETWORK_SSID="$HOME_NETWORK_SSID"
HOTSPOT_SSID="$HOTSPOT_SSID"
ADGUARD_DNS="$ADGUARD_DNS"
NETWORK_SERVICE="Wi-Fi"
EOF

chmod 644 "$CONFIG_FILE"

echo ""
echo "==================================="
echo "✓ Konfiguration gespeichert!"
echo "==================================="
echo ""
echo "Neue Konfiguration:"
echo "  Heimnetz SSID:  $HOME_NETWORK_SSID"
echo "  Hotspot SSID:   $HOTSPOT_SSID"
echo "  Adguard DNS:    $ADGUARD_DNS"
echo ""

# Service neu starten
read -p "Service jetzt neu starten? (j/n) [Standard: j]: " restart_service
restart_service=${restart_service:-j}

if [ "$restart_service" == "j" ] || [ "$restart_service" == "J" ]; then
    echo ""
    echo "Service wird neu gestartet..."

    # Service entladen
    if launchctl list | grep -q "com.auto-dns-switch"; then
        launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist 2>/dev/null
        sleep 1
    fi

    # Service neu laden
    launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist 2>/dev/null

    echo "✓ Service neu gestartet"
    echo ""
    echo "Die neuen Einstellungen sind jetzt aktiv."
else
    echo ""
    echo "Service wurde NICHT neu gestartet."
    echo "Die Änderungen werden beim nächsten Netzwerkwechsel aktiv."
    echo ""
    echo "Um den Service manuell neu zu starten:"
    echo "  sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist"
    echo "  sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist"
fi

echo ""

# Log-Eintrag
echo "$(date '+%Y-%m-%d %H:%M:%S') - Konfiguration aktualisiert: Heimnetz='$HOME_NETWORK_SSID', Hotspot='$HOTSPOT_SSID', DNS='$ADGUARD_DNS'" >> "$LOG_FILE"
