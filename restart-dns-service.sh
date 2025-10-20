#!/bin/bash

# Service-Neustart Script für Auto DNS Switcher
# Lädt den LaunchDaemon neu, um Konfigurationsänderungen zu aktivieren

echo "=== Auto DNS Switcher - Service Neustart ==="
echo ""

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "FEHLER: Dieses Script muss mit sudo ausgeführt werden!"
    echo "Bitte ausführen: sudo ./restart-dns-service.sh"
    exit 1
fi

# Prüfen ob Service installiert ist
if [ ! -f "/Library/LaunchDaemons/com.auto-dns-switch.plist" ]; then
    echo "FEHLER: Auto DNS Switcher ist nicht installiert."
    echo "Bitte zuerst installieren: sudo ./install-dns-switcher.sh"
    exit 1
fi

echo "Service wird neu gestartet..."
echo ""

# Service entladen
echo "Schritt 1/2: Service stoppen"
if launchctl list | grep -q "com.auto-dns-switch"; then
    launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist 2>/dev/null
    echo "✓ Service gestoppt"
else
    echo "ℹ Service war nicht aktiv"
fi

# Kurze Pause
sleep 1

# Service neu laden
echo ""
echo "Schritt 2/2: Service starten"
launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist 2>/dev/null

if launchctl list | grep -q "com.auto-dns-switch"; then
    echo "✓ Service gestartet"
else
    echo "⚠ Warnung: Service konnte nicht gestartet werden"
    echo "Bitte prüfen: sudo launchctl list | grep auto-dns-switch"
    exit 1
fi

echo ""
echo "==================================="
echo "✓ Service erfolgreich neu gestartet!"
echo "==================================="
echo ""
echo "Die aktuellen Konfigurationseinstellungen sind jetzt aktiv."
echo ""
echo "Log-Datei prüfen:"
echo "  tail -f /var/log/auto-dns-switch.log"
echo ""
