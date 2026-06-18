# AIMP AppImage Build

Dieses Verzeichnis enthält das Build-Skript zum Erstellen von drei portablen AppImages aus der installierten AIMP-Paketstruktur.

## Enthaltene Apps

| AppImage | Binär | Beschreibung |
|---|---|---|
| `AIMP-6.00-x86_64.AppImage` | `/opt/aimp/AIMP` | Audio-Player |
| `AudioConverter-6.00-x86_64.AppImage` | `/opt/aimp/AIMPac` | Audio-Konverter |
| `AdvancedTagEditor-6.00-x86_64.AppImage` | `/opt/aimp/AIMPate` | Tag-Editor für Audiodateien |

## Voraussetzungen

### Installiertes AIMP-Paket

Das AIMP-Paket muss auf dem **Build-System** (CachyOS/Arch) installiert sein. Das Build-Skript erwartet:

- Binaries und Libs unter `/opt/aimp/`
- Desktop-Dateien unter `/usr/share/applications/`
- Icons unter `/usr/share/icons/hicolor/`

```bash
# Paket installieren (Arch / CachyOS)
sudo pacman -U aimp-6.00-3067b-x86_64.pkg.tar.zst
```

### appimagetool

Das Skript liest den Pfad aus der Umgebungsvariable `APPIMAGETOOL` (Standard: `~/Downloads/appimagetool-x86_64.AppImage`).

```bash
export APPIMAGETOOL=/pfad/zu/appimagetool-x86_64.AppImage
```

Download: <https://github.com/AppImage/appimagetool/releases>

Das Tool muss ausführbar und auf einem Dateisystem ohne `noexec` liegen (CIFS/NFS-Shares sind oft mit `noexec` gemountet — in diesem Fall vorher nach `/tmp` kopieren):

```bash
cp /pfad/auf/share/appimagetool-x86_64.AppImage /tmp/
chmod +x /tmp/appimagetool-x86_64.AppImage
export APPIMAGETOOL=/tmp/appimagetool-x86_64.AppImage
```

## Bauen

```bash
cd ~/Downloads/aimp
APPIMAGETOOL=/tmp/appimagetool-x86_64.AppImage ./build-appimages.sh
```

Die fertigen AppImages (~70 MB) landen im selben Verzeichnis wie das Skript.

## Ausführen

AppImages müssen vor dem ersten Start ausführbar gemacht werden:

```bash
chmod +x AIMP-6.00-x86_64.AppImage
chmod +x AudioConverter-6.00-x86_64.AppImage
chmod +x AdvancedTagEditor-6.00-x86_64.AppImage
```

Danach direkt starten:

```bash
./AIMP-6.00-x86_64.AppImage
./AIMP-6.00-x86_64.AppImage /pfad/zur/musik.mp3
./AudioConverter-6.00-x86_64.AppImage /pfad/zur/datei.flac
./AdvancedTagEditor-6.00-x86_64.AppImage /pfad/zu/dateien/
```

## Desktop-Integration (optional)

Mit `appimaged` oder `AppImageLauncher` werden die AppImages automatisch ins Anwendungsmenü integriert und erhalten Dateiverknüpfungen.

Manuelle Integration:

```bash
mkdir -p ~/.local/bin
cp AIMP-6.00-x86_64.AppImage ~/.local/bin/

# Desktop-Datei und Icon aus dem AppImage extrahieren
./AIMP-6.00-x86_64.AppImage --appimage-extract-and-run
# -> legt squashfs-root/ im aktuellen Verzeichnis an
```

## Portabilität

Die AppImages laufen auf CachyOS/Arch sowie auf **Fedora 44-basierten Systemen** (Bazzite, Aurora) ohne zusätzliche Installationen.

### Gebündelte Libs

Neben den AIMP-eigenen Libs aus `/opt/aimp/` bündelt das Skript automatisch folgende Systemlibs, die auf anderen Distros fehlen oder eine andere Soname haben:

| Lib | Grund |
|---|---|
| `libbass-aimp.so` | Teil des AIMP-Arch-Pakets — auf Fedora/anderen Distros nicht vorhanden |
| `libicudata.so.78` + `libicuuc.so.78` | Soname-versioniert; Fedora 44 hat ICU 77 (`libicuuc.so.77`) |
| `libxml2.so.16` | Neue Soname seit libxml2 2.13 (Arch); Fedora 44 nutzt noch `.so.2` (libxml2 2.12.x) |
| `libglycin-2.so.0` | GNOME-Imageloader — fehlt auf KDE-basierten Systemen (Bazzite, Aurora) |
| `libtinysparql-3.0.so.0` | Umbenannt von `libtracker-sparql` — auf KDE-Systemen nicht standardmäßig installiert |

Der AppRun setzt `LD_LIBRARY_PATH` auf `$APPDIR/opt/aimp`, sodass alle gebündelten Libs vor Systemlibs geladen werden.

## Aufbau der AppImages

Jedes AppImage enthält die vollständige `/opt/aimp/`-Verzeichnisstruktur plus die gebündelten Portabilitäts-Libs:

```
AppDir/
  AppRun                        # Startskript (setzt LD_LIBRARY_PATH)
  <app>.desktop                 # Metadaten für Desktop-Integration
  <app>.png                     # Icon (256×256)
  .DirIcon -> <app>.png
  opt/
    aimp/
      AIMP / AIMPac / AIMPate   # Binaries
      libFLAC.so, libLAME.so, libMAC.so, libsoxrate.so, libwavpack.so
      libbass-aimp.so           # gebündelt aus /usr/lib/
      libicudata.so.78.3        # gebündelt aus /usr/lib/
      libicuuc.so.78.3          # gebündelt aus /usr/lib/
      libxml2.so.16.1.3         # gebündelt aus /usr/lib/
      libglycin-2.so.0          # gebündelt aus /usr/lib/
      libtinysparql-3.0.so.0.*  # gebündelt aus /usr/lib/
      Plugins/
      Skins/
      System/
      Langs/
      Help/
```

## Hinweise

- Alle drei AppImages sind voneinander unabhängig und bündeln jeweils die gesamte AIMP-Datenbasis.
- AIMP speichert Nutzerdaten weiterhin im Home-Verzeichnis (`~/.config/AIMP/` bzw. `~/.local/share/AIMP/`). Die AppImages verändern keine Systemdateien.
- Getestet auf CachyOS x86_64 mit AIMP 6.00 Build 3067b. Ziel-Systeme: Bazzite / Aurora (Fedora 44-Basis).
