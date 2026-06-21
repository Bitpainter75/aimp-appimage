# AIMP — AppImage

Unofficial AppImage builds of [AIMP](https://www.aimp.ru) for Linux, packaged for portability across distributions including Bazzite, Aurora, and other Fedora-based systems.

> This repository contains only the build script and releases.  
> AIMP is proprietary software by Artem Izmaylov. All rights reserved.

---

## AppImages

Three separate AppImages are provided, each containing the full AIMP library tree:

| AppImage | Binary | Description |
|---|---|---|
| `AIMP-6.00-x86_64.AppImage` | `AIMP` | Audio player |
| `AudioConverter-6.00-x86_64.AppImage` | `AIMPac` | Audio converter |
| `AdvancedTagEditor-6.00-x86_64.AppImage` | `AIMPate` | Audio tag editor |

Download the latest release from the [Releases](../../releases/latest) page.

---

## Usage

```bash
chmod +x AIMP-6.00-x86_64.AppImage
./AIMP-6.00-x86_64.AppImage
./AIMP-6.00-x86_64.AppImage /path/to/music.mp3

chmod +x AudioConverter-6.00-x86_64.AppImage
./AudioConverter-6.00-x86_64.AppImage /path/to/file.flac

chmod +x AdvancedTagEditor-6.00-x86_64.AppImage
./AdvancedTagEditor-6.00-x86_64.AppImage /path/to/files/
```

No installation required. All dependencies are bundled — no additional packages need to be installed.

---

## Desktop Integration (optional)

With [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) or [appimaged](https://github.com/probonopd/go-appimage), the AppImages are automatically integrated into your application menu and receive file associations.

Manual integration:

```bash
mkdir -p ~/.local/bin
cp AIMP-6.00-x86_64.AppImage ~/.local/bin/
# Right-click → Integrate in AppImageLauncher, or run appimaged
```

---

## Compatibility

| Distribution | Status |
|---|---|
| Bazzite / Aurora (Fedora 44) | ✅ tested |
| Fedora 40+ | ✅ expected |
| Arch / CachyOS / Manjaro | ✅ tested (build system) |
| Ubuntu 22.04+ | ✅ expected |
| Older distros (glibc < 2.34) | ❌ not supported |

---

## What's bundled

Beyond AIMP's own libraries from `/opt/aimp/`, the build script additionally bundles the following system libraries that may be missing or carry a different SONAME on non-Arch distributions:

| Library | Reason |
|---|---|
| `libbass-aimp.so` | Part of the AIMP Arch package — not present on other distros |
| `libavcodec-aimp.so.61` + `libavfilter-aimp.so.10` + `libavutil-aimp.so.59` + `libswresample-aimp.so.5` | AIMP-specific FFmpeg libs — loaded by `aimp_inputFFmpeg.so`, not present on other distros |
| `libicudata.so.78` + `libicuuc.so.78` | SONAME-pinned to v78; Fedora 44 ships ICU 77 (`libicuuc.so.77`) |
| `libxml2.so.16` | New SONAME since libxml2 2.13 (Arch); Fedora 44 still uses `.so.2` (libxml2 2.12.x) |
| `libglycin-2.so.0` | GNOME image loader — absent on KDE-based systems (Bazzite, Aurora) |
| `libtinysparql-3.0.so.0` | Renamed from `libtracker-sparql` — not installed on KDE systems by default |

`LD_LIBRARY_PATH` is set to `$APPDIR/opt/aimp` by AppRun so bundled libs are found before system libs.

---

## Build it yourself

### Prerequisites

AIMP must be installed on the **build system** (Arch / CachyOS). The script reads from `/opt/aimp/`:

```bash
# Install from the bundled package
sudo pacman -U aimp-6.00-3069b-x86_64.pkg.tar.zst
```

`appimagetool` must be available and executable. If it lives on a network share (CIFS/NFS with `noexec`), copy it to `/tmp` first:

```bash
cp /path/to/appimagetool-x86_64.AppImage /tmp/
chmod +x /tmp/appimagetool-x86_64.AppImage
```

Download appimagetool: <https://github.com/AppImage/appimagetool/releases>

### Build

```bash
git clone https://github.com/Bitpainter75/aimp-appimage.git
cd aimp-appimage
APPIMAGETOOL=/tmp/appimagetool-x86_64.AppImage ./build-appimages.sh
```

The three AppImages (~70 MB each) are written to the current directory.

### What the script does

1. Copies the full `/opt/aimp/` tree into each AppDir
2. Bundles the portability libs listed above (resolving symlinks to real files)
3. Patches the desktop file `Exec=` entries to work without a system installation
4. Removes the AudioConverter/TagEditor desktop Actions from the AIMP AppImage (they are separate AppImages)
5. Packs each AppDir into a self-contained AppImage with `appimagetool`

---

## User data

AIMP stores all user data in the home directory — the AppImages do not modify any system files:

| Data | Path |
|---|---|
| Configuration | `~/.config/AIMP/` |
| Library / playlists | `~/.local/share/AIMP/` |

---

## Links

- [AIMP official website](https://www.aimp.ru)
- [AIMP for Linux](https://www.aimp.ru/?do=download&os=linux)
- [appimagetool](https://github.com/AppImage/appimagetool)
