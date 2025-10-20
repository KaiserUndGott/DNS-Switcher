#!/bin/bash

# Deinstallationsskript für Auto DNS Switcher
# Stellt den Ausgangszustand wieder her und entfernt alle installierten Komponenten

echo "=== Auto DNS Switcher Deinstallation ==="
echo ""

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "FEHLER: Dieses Script muss mit sudo ausgeführt werden!"
    echo "Bitte ausführen: sudo ./uninstall-dns-switcher.sh"
    exit 1
fi

# Konfiguration laden für DNS-Wiederherstellung
CONFIG_FILE="/usr/local/etc/auto-dns-switch.conf"
NETWORK_SERVICE="Wi-Fi"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo "WARNUNG: Dies wird folgende Komponenten entfernen:"
echo "  - LaunchDaemon Service"
echo "  - Haupt-Script (/usr/local/bin/auto-dns-switch.sh)"
echo "  - Konfigurations-Script (/usr/local/bin/auto-dns-switch-config.sh)"
echo "  - Konfigurationsdatei (/usr/local/etc/auto-dns-switch.conf)"
echo "  - Log-Dateien (/var/log/auto-dns-switch*.log)"
echo ""
echo "Außerdem wird der DNS auf 'Automatisch (DHCP)' zurückgesetzt."
echo ""
read -p "Möchtest du fortfahren? (j/n): " confirm

if [ "$confirm" != "j" ] && [ "$confirm" != "J" ]; then
    echo "Deinstallation abgebrochen."
    exit 0
fi

echo ""
echo "==================================="
echo "Starte Deinstallation..."
echo "==================================="
echo ""

# Schritt 1: Service stoppen und entladen
echo "Schritt 1/6: LaunchDaemon stoppen"
echo "----------------------------"
if launchctl list | grep -q "com.auto-dns-switch"; then
    launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist 2>/dev/null
    echo "✓ Service gestoppt"
else
    echo "ℹ Service war nicht aktiv"
fi

# Schritt 2: LaunchDaemon Datei entfernen
echo ""
echo "Schritt 2/6: LaunchDaemon entfernen"
echo "----------------------------"
if [ -f "/Library/LaunchDaemons/com.auto-dns-switch.plist" ]; then
    rm /Library/LaunchDaemons/com.auto-dns-switch.plist
    echo "✓ LaunchDaemon entfernt"
else
    echo "ℹ LaunchDaemon war nicht installiert"
fi

# Schritt 3: Scripts entfernen
echo ""
echo "Schritt 3/6: Scripts entfernen"
echo "----------------------------"
REMOVED_SCRIPTS=0

if [ -f "/usr/local/bin/auto-dns-switch.sh" ]; then
    rm /usr/local/bin/auto-dns-switch.sh
    echo "✓ Haupt-Script entfernt"
    REMOVED_SCRIPTS=$((REMOVED_SCRIPTS + 1))
fi

if [ -f "/usr/local/bin/auto-dns-switch-config.sh" ]; then
    rm /usr/local/bin/auto-dns-switch-config.sh
    echo "✓ Konfigurations-Script entfernt"
    REMOVED_SCRIPTS=$((REMOVED_SCRIPTS + 1))
fi

if [ $REMOVED_SCRIPTS -eq 0 ]; then
    echo "ℹ Keine Scripts gefunden"
fi

# Schritt 4: Konfigurationsdatei entfernen
echo ""
echo "Schritt 4/6: Konfigurationsdatei entfernen"
echo "----------------------------"
if [ -f "$CONFIG_FILE" ]; then
    # Konfiguration anzeigen bevor gelöscht wird
    echo "Letzte Konfiguration:"
    if [ -n "$HOME_NETWORK_SSID" ]; then
        echo "  - Heimnetz SSID: $HOME_NETWORK_SSID"
    fi
    if [ -n "$HOTSPOT_SSID" ]; then
        echo "  - Hotspot SSID: $HOTSPOT_SSID"
    fi
    if [ -n "$ADGUARD_DNS" ]; then
        echo "  - Adguard DNS: $ADGUARD_DNS"
    fi
    rm "$CONFIG_FILE"
    echo "✓ Konfigurationsdatei entfernt"
else
    echo "ℹ Keine Konfigurationsdatei gefunden"
fi

# Schritt 5: Log-Dateien entfernen
echo ""
echo "Schritt 5/6: Log-Dateien entfernen"
echo "----------------------------"
REMOVED_LOGS=0

if [ -f "/var/log/auto-dns-switch.log" ]; then
    rm /var/log/auto-dns-switch.log
    echo "✓ Haupt-Log entfernt"
    REMOVED_LOGS=$((REMOVED_LOGS + 1))
fi

if [ -f "/var/log/auto-dns-switch-error.log" ]; then
    rm /var/log/auto-dns-switch-error.log
    echo "✓ Fehler-Log entfernt"
    REMOVED_LOGS=$((REMOVED_LOGS + 1))
fi

if [ $REMOVED_LOGS -eq 0 ]; then
    echo "ℹ Keine Log-Dateien gefunden"
fi

# Schritt 6: DNS auf Ausgangszustand zurücksetzen
echo ""
echo "Schritt 6/6: DNS-Einstellungen zurücksetzen"
echo "----------------------------"

# Aktuellen DNS prüfen
CURRENT_DNS=$(networksetup -getdnsservers "$NETWORK_SERVICE" | head -n 1)

if [ "$CURRENT_DNS" != "There aren't any DNS Servers set on $NETWORK_SERVICE." ]; then
    echo "Aktueller DNS: $CURRENT_DNS"
    echo "Setze DNS auf 'Automatisch (DHCP)' zurück..."
    networksetup -setdnsservers "$NETWORK_SERVICE" "Empty"
    echo "✓ DNS auf Automatisch (DHCP) zurückgesetzt"
else
    echo "✓ DNS war bereits auf Automatisch (DHCP)"
fi

# Prüfen ob Änderung erfolgreich war
FINAL_DNS=$(networksetup -getdnsservers "$NETWORK_SERVICE" | head -n 1)
if [ "$FINAL_DNS" == "There aren't any DNS Servers set on $NETWORK_SERVICE." ]; then
    echo "✓ DNS-Wiederherstellung erfolgreich"
fi

echo ""
echo "==================================="
echo "✓ Deinstallation abgeschlossen!"
echo "==================================="
echo ""
echo "Alle Komponenten wurden erfolgreich entfernt:"
echo "  ✓ LaunchDaemon Service gestoppt und entfernt"
echo "  ✓ Scripts entfernt"
echo "  ✓ Konfigurationsdatei gelöscht"
echo "  ✓ Log-Dateien gelöscht"
echo "  ✓ DNS auf Automatisch (DHCP) zurückgesetzt"
echo ""
echo "Dein System ist wieder im Ausgangszustand."
echo ""
echo "Falls du die Installation erneut durchführen möchtest:"
echo "  sudo ./install-dns-switcher.sh"
echo ""
