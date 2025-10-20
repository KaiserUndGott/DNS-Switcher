# Auto DNS Switcher für macOS

Automatischer DNS-Wechsel zwischen Adguard (Heimnetz) und DHCP (Hotspot/andere Netze) für macOS 26+ (Sequoia und höher).

## Problem

- **Im Heimnetz**: Adguard DNS (192.168.128.253) soll verwendet werden - auch wenn gleichzeitig per Kabel und WLAN verbunden
- **Bei Handy-Hotspot**: Kein Zugriff auf Heimnetz-DNS → kein Internet
- **Lösung**: Automatischer Wechsel basierend auf WLAN-SSID

## Features

✅ Erkennt Heimnetz und Hotspot anhand der SSID
✅ Funktioniert auch bei paralleler Kabel + WLAN Verbindung
✅ Automatische Warnung bei unbekannten Netzwerken
✅ Einfache Rekonfiguration wenn sich Hotspot-Name ändert
✅ Vollständige Deinstallationsroutine mit Ausgangszustand-Wiederherstellung
✅ Kompatibel mit macOS Sequoia 26.x und höher
✅ Läuft automatisch im Hintergrund bei jedem Netzwerkwechsel

## Installation

```bash
cd /Users/fbw/Documents/Entwicklung/DNS-Switcher
sudo ./install-dns-switcher.sh
```

Das Installationsskript fragt dich nach:
1. **Heimnetz-SSID** (z.B. "Wo der Frosch die Locken hat")
2. **Hotspot-SSID** (z.B. "Hotzpotz@2704")
3. **Adguard DNS-IP** (Standard: 192.168.128.253)

## Funktionsweise

Das Script erkennt automatisch das verbundene WLAN:

| WLAN SSID | DNS Einstellung | Beschreibung |
|-----------|----------------|--------------|
| **Heimnetz-SSID** | 192.168.128.253 (Adguard) | Nutzt deinen Adguard DNS-Server |
| **Hotspot-SSID** | Automatisch (DHCP) | Nutzt DNS vom Handy-Hotspot |
| **Unbekannte SSID** | Automatisch (DHCP) + Warnung im Log | Sicherer Fallback |

### Besonderheiten

- **Parallele Verbindungen**: Funktioniert auch wenn du gleichzeitig per Kabel UND WLAN verbunden bist
- **Hotspot-Priorität**: Wenn Hotspot-WLAN aktiv ist, wird automatisch auf DHCP umgeschaltet (auch bei vorhandener Kabelverbindung)
- **Unbekannte Netzwerke**: Script schreibt Warnung ins Log und bietet Rekonfiguration an

## Nützliche Befehle

### Log-Datei live anzeigen
```bash
tail -f /var/log/auto-dns-switch.log
```

### Hotspot-SSID ändern (z.B. nach Handy-Wechsel)
```bash
sudo /usr/local/bin/auto-dns-switch-config.sh
```

Interaktives Menü:
1. Heimnetz SSID ändern
2. Hotspot SSID ändern
3. Beide SSIDs ändern
4. Adguard DNS-IP ändern
5. Aktuelle Konfiguration anzeigen

### Aktuellen DNS prüfen
```bash
networksetup -getdnsservers Wi-Fi
```

### Service neu starten

**Automatisch (empfohlen):**
```bash
cd /Users/fbw/Documents/Entwicklung/DNS-Switcher
sudo ./restart-dns-service.sh
```

**Manuell:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

### Service-Status prüfen
```bash
sudo launchctl list | grep auto-dns-switch
```

### Script manuell ausführen (zum Testen)
```bash
sudo /usr/local/bin/auto-dns-switch.sh
tail -10 /var/log/auto-dns-switch.log
```

## Deinstallation

### Automatische Deinstallation (empfohlen)

Das Deinstallationsskript entfernt alle Komponenten und stellt den Ausgangszustand wieder her:

```bash
cd /Users/fbw/Documents/Entwicklung/DNS-Switcher
sudo ./uninstall-dns-switcher.sh
```

Das Script:
- ✓ Stoppt und entfernt den LaunchDaemon Service
- ✓ Löscht alle installierten Scripts
- ✓ Entfernt die Konfigurationsdatei
- ✓ Löscht alle Log-Dateien
- ✓ Setzt DNS auf Automatisch (DHCP) zurück

### Manuelle Deinstallation

Falls du die Komponenten manuell entfernen möchtest:

```bash
# Service stoppen
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist

# Komponenten entfernen
sudo rm /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo rm /usr/local/bin/auto-dns-switch.sh
sudo rm /usr/local/bin/auto-dns-switch-config.sh
sudo rm /usr/local/etc/auto-dns-switch.conf
sudo rm /var/log/auto-dns-switch.log
sudo rm /var/log/auto-dns-switch-error.log

# DNS zurücksetzen
networksetup -setdnsservers Wi-Fi "Empty"
```

## Konfigurationsdateien

- **Haupt-Script**: `/usr/local/bin/auto-dns-switch.sh`
- **Config-Tool**: `/usr/local/bin/auto-dns-switch-config.sh`
- **Konfiguration**: `/usr/local/etc/auto-dns-switch.conf`
- **LaunchDaemon**: `/Library/LaunchDaemons/com.auto-dns-switch.plist`
- **Log-Datei**: `/var/log/auto-dns-switch.log`

## Manuelle Konfiguration

Falls du die Konfigurationsdatei manuell bearbeiten möchtest:

```bash
sudo nano /usr/local/etc/auto-dns-switch.conf
```

Wichtige Parameter:
```bash
HOME_NETWORK_SSID="Wo der Frosch die Locken hat"  # Deine Heimnetz-SSID
HOTSPOT_SSID="Hotzpotz@2704"                       # Deine Hotspot-SSID
ADGUARD_DNS="192.168.128.253"                      # Deine Adguard DNS-IP
NETWORK_SERVICE="Wi-Fi"                            # Name des WLAN-Service
```

Nach Änderungen Service neu starten:
```bash
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

## Troubleshooting

### Script läuft nicht automatisch

```bash
# Service-Status prüfen
sudo launchctl list | grep auto-dns-switch

# Fehler-Log anzeigen
cat /var/log/auto-dns-switch-error.log

# Service manuell starten
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

### DNS wird nicht umgestellt

```bash
# Aktuellen DNS prüfen
networksetup -getdnsservers Wi-Fi

# Aktuelle SSID prüfen
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
networksetup -getairportnetwork "$WIFI_DEVICE"

# Script manuell testen
sudo /usr/local/bin/auto-dns-switch.sh

# Log prüfen
tail -20 /var/log/auto-dns-switch.log
```

### Unbekanntes Netzwerk erkannt

Wenn du ein unbekanntes WLAN siehst (z.B. nach Änderung der Hotspot-SSID):

1. Prüfe das Log:
   ```bash
   tail -20 /var/log/auto-dns-switch.log
   ```

2. Aktualisiere die Hotspot-SSID:
   ```bash
   sudo /usr/local/bin/auto-dns-switch-config.sh
   ```

3. Wähle Option 2 (Hotspot SSID ändern)

### Falsche SSID konfiguriert

```bash
# Aktuelle SSID anzeigen
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
networksetup -getairportnetwork "$WIFI_DEVICE"

# Konfiguration aktualisieren
sudo /usr/local/bin/auto-dns-switch-config.sh

# Service neu starten
sudo launchctl unload /Library/LaunchDaemons/com.auto-dns-switch.plist
sudo launchctl load /Library/LaunchDaemons/com.auto-dns-switch.plist
```

## Kompatibilität

- **macOS Version**: Sequoia 26.x und höher
- **Getestet auf**: macOS 26.0.1 (Build 25A362)
- **WiFi-Interface**: Automatische Erkennung (en0, en1, etc.)
- **Netzwerk-Service**: Wi-Fi (Standard)

## Technische Details

Das Script nutzt:
- `networksetup -getairportnetwork` für SSID-Erkennung (ersetzt veraltetes `airport` Tool)
- `networksetup -setdnsservers` für DNS-Umstellung
- LaunchDaemon mit `WatchPaths` für automatische Ausführung bei Netzwerkänderungen
- Konfigurationsdatei in `/usr/local/etc/` für persistente Einstellungen

## Lizenz

Dieses Projekt ist Open Source und frei verwendbar.

## Support

Bei Problemen oder Fragen:
1. Prüfe das Log: `tail -f /var/log/auto-dns-switch.log`
2. Erstelle ein Issue auf GitHub
3. Inkludiere relevante Log-Einträge

---

**Erstellt mit [Claude Code](https://claude.com/claude-code)**
