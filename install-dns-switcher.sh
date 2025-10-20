#!/bin/bash

# Installationsskript für Auto DNS Switcher

echo "=== Auto DNS Switcher Installation ==="
echo ""

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "FEHLER: Dieses Script muss mit sudo ausgeführt werden!"
    echo "Bitte ausführen: sudo ./install-dns-switcher.sh"
    exit 1
fi

# SSID abfragen
echo "Schritt 1/4: Konfiguration"
echo "----------------------------"
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
current_ssid=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null | awk -F': ' '{print $2}')

if [ -n "$current_ssid" ]; then
    echo "Aktuell verbundenes WLAN: $current_ssid"
    read -p "Ist das dein Heimnetz? (j/n): " is_home

    if [ "$is_home" == "j" ] || [ "$is_home" == "J" ]; then
        HOME_SSID="$current_ssid"
    else
        read -p "Bitte gib die SSID deines Heimnetzes ein: " HOME_SSID
    fi
else
    read -p "Bitte gib die SSID deines Heimnetzes ein: " HOME_SSID
fi

# Script anpassen und kopieren
echo ""
echo "Schritt 2/4: Script Installation"
echo "----------------------------"
sed "s/DEIN_HEIMNETZ_SSID/$HOME_SSID/" auto-dns-switch.sh > /tmp/auto-dns-switch.sh
chmod +x /tmp/auto-dns-switch.sh
mv /tmp/auto-dns-switch.sh /usr/local/bin/auto-dns-switch.sh
echo "✓ Script nach /usr/local/bin/ kopiert"

# LaunchDaemon installieren
echo ""
echo "Schritt 3/4: LaunchDaemon Installation"
echo "----------------------------"
cp com.auto-dns-switch.plist /Library/LaunchDaemons/
chmod 644 /Library/LaunchDaemons/com.auto-dns-switch.plist
chown root:wheel /Library/LaunchDaemons/com.auto-dns-switch.plist
echo "✓ LaunchDaemon konfiguriert"

# Log-Datei vorbereiten
touch /var/log/auto-dns-switch.log
chmod 644 /var/log/auto-dns-switch.log

# LaunchDaemon laden
echo ""
echo "Schritt 4/4: Service starten"
echo "----------------------------"
launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
echo "✓ Service gestartet"

echo ""
echo "==================================="
echo "✓ Installation erfolgreich!"
echo "==================================="
echo ""
echo "Der DNS-Switcher läuft jetzt automatisch bei jedem Netzwerkwechsel."
echo ""
echo "Konfiguration:"
echo "  - Heimnetz SSID: $HOME_SSID"
echo "  - Heimnetz DNS: 192.168.128.253 (Adguard)"
echo "  - Andere Netze: Automatisch (DHCP)"
echo ""
echo "Log-Datei anzeigen:"
echo "  tail -f /var/log/auto-dns-switch.log"
echo ""
echo "Deinstallation:"
echo "  sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist"
echo "  sudo rm /Library/LaunchDaemons/com.auto-dns-switch.plist"
echo "  sudo rm /usr/local/bin/auto-dns-switch.sh"
echo ""
