#!/usr/bin/env bash
# Baut 3 AppImages aus der installierten AIMP-6.00-Paketstruktur:
#   AIMP-6.00-x86_64.AppImage
#   AudioConverter-6.00-x86_64.AppImage
#   AdvancedTagEditor-6.00-x86_64.AppImage

set -euo pipefail

APPIMAGETOOL="${APPIMAGETOOL:-/home/patrick/Downloads/appimagetool-x86_64.AppImage}"
AIMP_SRC="/opt/aimp"
ICON_DIR="/usr/share/icons/hicolor"
DESK_DIR="/usr/share/applications"
OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/aimp-appimage-$$"

VERSION="6.00"

# ---------------------------------------------------------------------------
die() { echo "FEHLER: $*" >&2; exit 1; }

[[ -x "$APPIMAGETOOL" ]] || die "appimagetool nicht gefunden: $APPIMAGETOOL"
[[ -d "$AIMP_SRC"     ]] || die "AIMP-Quellverzeichnis nicht gefunden: $AIMP_SRC"

mkdir -p "$BUILD_DIR"
trap 'rm -rf "$BUILD_DIR"' EXIT

# ---------------------------------------------------------------------------
# Hilfsfunktion: /opt/aimp vollständig in AppDir/opt/aimp kopieren
copy_aimp_tree() {
    local appdir="$1"
    mkdir -p "$appdir/opt/aimp"
    cp -a "$AIMP_SRC/." "$appdir/opt/aimp/"
}

# ---------------------------------------------------------------------------
# Portabilitäts-Libs bündeln: Libs die AIMP aus /usr/lib/ lädt und die auf
# anderen Distros (Fedora/Bazzite/Aurora) fehlen oder eine andere Soname haben.
#
#   libbass-aimp.so       – Teil des AIMP-Pakets, auf fremden Systemen nicht vorhanden
#   libicudata/uc.so.78   – Soname-pinned auf v78; Fedora hat v74–76
#   libxml2.so.16         – Arch-Soname (libxml2 2.13); Fedora nutzt noch .so.2
#   libglycin-2.so.0      – GNOME-Imageloader, fehlt auf nicht-GNOME-Systemen
#   libtinysparql-3.0.so.0 – Umbenannt von libtracker-sparql; ältere Distros kennen den Namen nicht
bundle_portable_libs() {
    local libdir="$1/opt/aimp"
    local libs=(
        /usr/lib/libbass-aimp.so
        /usr/lib/libicudata.so.78
        /usr/lib/libicuuc.so.78
        /usr/lib/libxml2.so.16
        /usr/lib/libglycin-2.so.0
        /usr/lib/libtinysparql-3.0.so.0
    )
    for lib in "${libs[@]}"; do
        if [[ -e "$lib" ]]; then
            # Symlinks auflösen und reale Datei kopieren, dann Soname-Symlink anlegen
            local real; real="$(readlink -f "$lib")"
            cp "$real" "$libdir/$(basename "$real")"
            local soname; soname="$(basename "$lib")"
            if [[ "$(basename "$real")" != "$soname" ]]; then
                ln -sf "$(basename "$real")" "$libdir/$soname"
            fi
            echo "  Gebündelt: $lib -> $(basename "$real")"
        else
            echo "  WARNUNG: $lib nicht gefunden, wird übersprungen" >&2
        fi
    done
}

# ---------------------------------------------------------------------------
build_aimp() {
    echo ">>> Baue AIMP AppImage ..."
    local appdir="$BUILD_DIR/AIMP.AppDir"
    mkdir -p "$appdir"

    copy_aimp_tree "$appdir"
    bundle_portable_libs "$appdir"

    # Desktop-Datei – Exec auf AppRun-kompatiblen Wert setzen
    local desk="$appdir/aimp.desktop"
    cp "$DESK_DIR/aimp.desktop" "$desk"
    # Exec=aimp → Exec=AIMP (wird von AppRun aufgelöst)
    sed -i \
        -e 's|^Exec=aimp\b|Exec=AIMP|' \
        -e 's|^Exec=aimp -|Exec=AIMP -|g' \
        "$desk"
    # Action-Exec-Zeilen ebenfalls anpassen
    sed -i 's|^Exec=aimp |Exec=AIMP |g' "$desk"

    # AudioConverter/TagEditor-Actions zeigen auf absolute /opt/aimp/-Pfade,
    # die auf dem Zielsystem nicht existieren. Da beide Tools eigene AppImages haben,
    # werden diese Actions aus der AIMP-Desktop-Datei entfernt.
    sed -i 's/;AudioConverter;TagEditor;/;/' "$desk"
    sed -i '/^\[Desktop Action AudioConverter\]/,/^[[:space:]]*$/d' "$desk"
    sed -i '/^\[Desktop Action TagEditor\]/,/^[[:space:]]*$/d' "$desk"

    # Icon
    cp "$ICON_DIR/256x256/apps/aimp.png" "$appdir/aimp.png"
    ln -sf aimp.png "$appdir/.DirIcon"

    # AppRun
    cat > "$appdir/AppRun" << 'APPRUN'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$APPDIR/opt/aimp${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$APPDIR/opt/aimp/AIMP" "$@"
APPRUN
    chmod +x "$appdir/AppRun"

    ARCH=x86_64 "$APPIMAGETOOL" "$appdir" \
        "$OUTPUT_DIR/AIMP-${VERSION}-x86_64.AppImage"
    echo "    -> $OUTPUT_DIR/AIMP-${VERSION}-x86_64.AppImage"
}

# ---------------------------------------------------------------------------
build_converter() {
    echo ">>> Baue Audio Converter AppImage ..."
    local appdir="$BUILD_DIR/AudioConverter.AppDir"
    mkdir -p "$appdir"

    copy_aimp_tree "$appdir"
    bundle_portable_libs "$appdir"

    local desk="$appdir/aimp-ac.desktop"
    cp "$DESK_DIR/aimp.utils.converter.desktop" "$desk"
    sed -i \
        -e 's|^Exec=/opt/aimp/AIMPac|Exec=AIMPac|' \
        "$desk"
    # AppImage erwartet, dass Name des Desktop-Files dem Icon entspricht
    sed -i 's|^Icon=.*|Icon=aimp-ac|' "$desk"

    cp "$ICON_DIR/256x256/apps/aimp-ac.png" "$appdir/aimp-ac.png"
    ln -sf aimp-ac.png "$appdir/.DirIcon"

    cat > "$appdir/AppRun" << 'APPRUN'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$APPDIR/opt/aimp${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$APPDIR/opt/aimp/AIMPac" "$@"
APPRUN
    chmod +x "$appdir/AppRun"

    ARCH=x86_64 "$APPIMAGETOOL" "$appdir" \
        "$OUTPUT_DIR/AudioConverter-${VERSION}-x86_64.AppImage"
    echo "    -> $OUTPUT_DIR/AudioConverter-${VERSION}-x86_64.AppImage"
}

# ---------------------------------------------------------------------------
build_tageditor() {
    echo ">>> Baue Advanced Tag Editor AppImage ..."
    local appdir="$BUILD_DIR/AdvancedTagEditor.AppDir"
    mkdir -p "$appdir"

    copy_aimp_tree "$appdir"
    bundle_portable_libs "$appdir"

    local desk="$appdir/aimp-ate.desktop"
    cp "$DESK_DIR/aimp.utils.tageditor.desktop" "$desk"
    sed -i \
        -e 's|^Exec=/opt/aimp/AIMPate|Exec=AIMPate|' \
        "$desk"
    sed -i 's|^Icon=.*|Icon=aimp-ate|' "$desk"

    cp "$ICON_DIR/256x256/apps/aimp-ate.png" "$appdir/aimp-ate.png"
    ln -sf aimp-ate.png "$appdir/.DirIcon"

    cat > "$appdir/AppRun" << 'APPRUN'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$APPDIR/opt/aimp${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$APPDIR/opt/aimp/AIMPate" "$@"
APPRUN
    chmod +x "$appdir/AppRun"

    ARCH=x86_64 "$APPIMAGETOOL" "$appdir" \
        "$OUTPUT_DIR/AdvancedTagEditor-${VERSION}-x86_64.AppImage"
    echo "    -> $OUTPUT_DIR/AdvancedTagEditor-${VERSION}-x86_64.AppImage"
}

# ---------------------------------------------------------------------------
build_aimp
build_converter
build_tageditor

echo ""
echo "Fertig. Alle 3 AppImages liegen in: $OUTPUT_DIR"
