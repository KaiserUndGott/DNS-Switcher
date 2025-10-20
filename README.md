# Auto DNS Switcher für macOS

Automatischer DNS-Wechsel zwischen Adguard (Heimnetz) und DHCP (Hotspot/andere Netze).

## Problem

- Im Heimnetz: Adguard DNS (192.168.128.253) soll verwendet werden
- Bei Handy-Hotspot: Kein Zugriff auf Heimnetz-DNS → kein Internet
- Lösung: Automatischer Wechsel basierend auf SSID

## Installation

```bash
sudo ./install-dns-switcher.sh
```

Das Installationsskript:
1. Fragt nach deiner Heimnetz-SSID
2. Installiert das Script nach `/usr/local/bin/`
3. Richtet einen LaunchDaemon ein (startet automatisch)
4. Aktiviert den Service

## Funktionsweise

- **Heimnetz erkannt** (deine SSID): Setzt DNS auf 192.168.128.253, 192.168.128.254, 1.1.1.1
- **Anderes Netz erkannt**: Setzt DNS auf automatisch (DHCP vom Hotspot)
- **Trigger**: Läuft automatisch bei jedem Netzwerkwechsel

## Befehle

### Log-Datei anzeigen
```bash
tail -f /var/log/auto-dns-switch.log
```

### Service neu starten
```bash
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

### Status prüfen
```bash
sudo launchctl list | grep auto-dns-switch
```

### Manuell ausführen (zum Testen)
```bash
sudo /usr/local/bin/auto-dns-switch.sh
```

## Deinstallation

```bash
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo rm /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo rm /usr/local/bin/auto-dns-switch.sh
sudo rm /var/log/auto-dns-switch.log
sudo rm /var/log/auto-dns-switch-error.log
```

## Anpassungen

Falls du die SSID ändern oder weitere Einstellungen vornehmen möchtest:

```bash
sudo nano /usr/local/bin/auto-dns-switch.sh
```

Wichtige Variablen:
- `HOME_NETWORK_SSID`: SSID deines Heimnetzes
- `ADGUARD_DNS`: IP deines Adguard-Servers (Standard: 192.168.128.253)
- `NETWORK_SERVICE`: Name der Netzwerkschnittstelle (Standard: "Wi-Fi")

Nach Änderungen Service neu starten:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

## Dateien

- `/Users/fbw/auto-dns-switch.sh` - Haupt-Script
- `/Users/fbw/com.auto-dns-switch.plist` - LaunchDaemon Konfiguration
- `/Users/fbw/install-dns-switcher.sh` - Installations-Script
- `/usr/local/bin/auto-dns-switch.sh` - Installiertes Script
- `/Library/LaunchDaemons/com.auto-dns-switch.plist` - Aktiver LaunchDaemon
- `/var/log/auto-dns-switch.log` - Log-Datei

## Troubleshooting

### Script läuft nicht automatisch
```bash
# Service-Status prüfen
sudo launchctl list | grep auto-dns-switch

# Fehler-Log anzeigen
cat /var/log/auto-dns-switch-error.log
```

### DNS wird nicht umgestellt
```bash
# Aktuellen DNS prüfen
networksetup -getdnsservers Wi-Fi

# Script manuell testen
sudo /usr/local/bin/auto-dns-switch.sh

# Log prüfen
tail -20 /var/log/auto-dns-switch.log
```

### Falsche SSID konfiguriert
```bash
# Aktuelle SSID anzeigen
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep SSID

# Script bearbeiten
sudo nano /usr/local/bin/auto-dns-switch.sh
# Ändere HOME_NETWORK_SSID="..." zur korrekten SSID

# Service neu starten
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```
