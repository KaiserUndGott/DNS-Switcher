#!/bin/bash

# Installationsskript für Auto DNS Switcher
# Kompatibel mit macOS 26+ (Sequoia und höher)

echo "=== Auto DNS Switcher Installation ==="
echo ""

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "FEHLER: Dieses Script muss mit sudo ausgeführt werden!"
    echo "Bitte ausführen: sudo ./install-dns-switcher.sh"
    exit 1
fi

# SSIDs abfragen
echo "Schritt 1/5: Konfiguration"
echo "----------------------------"
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
current_ssid=$(networksetup -getairportnetwork "$WIFI_DEVICE" 2>/dev/null | awk -F': ' '{print $2}')

# Heimnetz SSID
if [[ "$current_ssid" != *"not associated"* ]] && [ -n "$current_ssid" ]; then
    echo "Aktuell verbundenes WLAN: '$current_ssid'"
    read -p "Ist das dein Heimnetz? (j/n): " is_home

    if [ "$is_home" == "j" ] || [ "$is_home" == "J" ]; then
        HOME_SSID="$current_ssid"
    else
        read -p "Bitte gib die SSID deines Heimnetzes ein: " HOME_SSID
    fi
else
    read -p "Bitte gib die SSID deines Heimnetzes ein: " HOME_SSID
fi

# Hotspot SSID
echo ""
read -p "Bitte gib die SSID deines Handy-Hotspots ein: " HOTSPOT_SSID

# Adguard DNS (optional anpassen)
echo ""
read -p "Adguard DNS-IP [Standard: 192.168.128.253]: " ADGUARD_DNS
if [ -z "$ADGUARD_DNS" ]; then
    ADGUARD_DNS="192.168.128.253"
fi

echo ""
echo "Konfiguration:"
echo "  Heimnetz SSID:  $HOME_SSID"
echo "  Hotspot SSID:   $HOTSPOT_SSID"
echo "  Adguard DNS:    $ADGUARD_DNS"
echo ""
read -p "Ist das korrekt? (j/n): " confirm

if [ "$confirm" != "j" ] && [ "$confirm" != "J" ]; then
    echo "Installation abgebrochen."
    exit 1
fi

# Konfigurationsdatei erstellen
echo ""
echo "Schritt 2/5: Konfigurationsdatei erstellen"
echo "----------------------------"
mkdir -p /usr/local/etc
cat > /usr/local/etc/auto-dns-switch.conf <<EOF
# Auto DNS Switcher Konfiguration
# Erstellt: $(date '+%Y-%m-%d %H:%M:%S')

HOME_NETWORK_SSID="$HOME_SSID"
HOTSPOT_SSID="$HOTSPOT_SSID"
ADGUARD_DNS="$ADGUARD_DNS"
NETWORK_SERVICE="Wi-Fi"
EOF
chmod 644 /usr/local/etc/auto-dns-switch.conf
echo "✓ Konfiguration nach /usr/local/etc/ gespeichert"

# Scripts kopieren
echo ""
echo "Schritt 3/5: Scripts Installation"
echo "----------------------------"
cp auto-dns-switch.sh /usr/local/bin/auto-dns-switch.sh
chmod +x /usr/local/bin/auto-dns-switch.sh
echo "✓ Haupt-Script nach /usr/local/bin/ kopiert"

cp auto-dns-switch-config.sh /usr/local/bin/auto-dns-switch-config.sh
chmod +x /usr/local/bin/auto-dns-switch-config.sh
echo "✓ Konfigurations-Script nach /usr/local/bin/ kopiert"

# LaunchDaemon installieren
echo ""
echo "Schritt 4/5: LaunchDaemon Installation"
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
echo "Schritt 5/5: Service starten"
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
echo "  - Heimnetz SSID:  $HOME_SSID → DNS: $ADGUARD_DNS (Adguard)"
echo "  - Hotspot SSID:   $HOTSPOT_SSID → DNS: Automatisch (DHCP)"
echo "  - Andere Netze:   → DNS: Automatisch (DHCP) + Warnung im Log"
echo ""
echo "Nützliche Befehle:"
echo "  Log-Datei live anzeigen:"
echo "    tail -f /var/log/auto-dns-switch.log"
echo ""
echo "  Hotspot-SSID später ändern:"
echo "    sudo /usr/local/bin/auto-dns-switch-config.sh"
echo ""
echo "  Service neu starten:"
echo "    sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist"
echo "    sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist"
echo ""
echo "  Deinstallation (mit Ausgangszustand-Wiederherstellung):"
echo "    cd $(dirname "$0")"
echo "    sudo ./uninstall-dns-switcher.sh"
echo ""
