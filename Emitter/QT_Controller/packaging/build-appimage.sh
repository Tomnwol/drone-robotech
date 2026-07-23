#!/usr/bin/env bash
# Build a portable AppImage for drone_controller (Linux x86_64).
# Requires: cmake, g++, Qt6 (system), libevdev, curl — see ../install-deps.sh
# linuxdeploy tools are downloaded once into packaging/tools/

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/packaging"
TOOLS="$PKG/tools"
BUILD="$ROOT/build-appimage"
APPDIR="$BUILD/AppDir"
OUT="$ROOT/drone_controller-x86_64.AppImage"
ARCH="$(uname -m)"

if [[ "$ARCH" != "x86_64" ]]; then
    echo "Error: AppImage packaging script currently targets x86_64 (got $ARCH)."
    exit 1
fi

mkdir -p "$TOOLS" "$BUILD"

download() {
    local url="$1" dest="$2"
    if [[ -x "$dest" ]]; then
        return 0
    fi
    echo "Downloading $(basename "$dest")..."
    curl -fsSL -L -o "$dest" "$url"
    chmod +x "$dest"
}

download \
    "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" \
    "$TOOLS/linuxdeploy-x86_64.AppImage"
download \
    "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage" \
    "$TOOLS/linuxdeploy-plugin-qt-x86_64.AppImage"

# Prefer extract-and-run (no FUSE needed on WSL/CI)
export APPIMAGE_EXTRACT_AND_RUN=1
export PATH="$TOOLS:$PATH"
# Scan app QML + explicit imports (WorkerScript is transitive and often missed)
export QML_SOURCES_PATHS="$ROOT:$PKG"

# Force Qt6: plain `qmake` often points to Qt5 via qtchooser
if [[ -x /usr/bin/qmake6 ]]; then
    export QMAKE=/usr/bin/qmake6
elif command -v qmake6 >/dev/null 2>&1; then
    export QMAKE="$(command -v qmake6)"
else
    echo "Error: qmake6 not found (needed by linuxdeploy-plugin-qt for Qt6)."
    exit 1
fi
echo "Using QMAKE=$QMAKE ($("$QMAKE" -query QT_VERSION))"

QML_ROOT="$("$QMAKE" -query QT_INSTALL_QML)"
for rel in QtQml "QtQml/Models" "QtQml/WorkerScript" QtQuick QtQuick3D; do
    if [[ ! -d "$QML_ROOT/$rel" ]]; then
        echo "Error: missing QML module $rel under $QML_ROOT"
        echo "Install runtime QML packages, e.g. on Ubuntu:"
        echo "  sudo apt install qml6-module-qtqml qml6-module-qtqml-models qml6-module-qtqml-workerscript \\"
        echo "                   qml6-module-qtquick qml6-module-quick3d"
        echo "Or re-run: ./install-deps.sh"
        exit 1
    fi
done
export QML_MODULES_PATHS="$QML_ROOT${QML_MODULES_PATHS:+:$QML_MODULES_PATHS}"

# Ensure 8-bit PNG icon (linuxdeploy rejects SVG / 16-bit PNG as root icon)
if [[ ! -f "$PKG/drone_controller.png" ]] && command -v convert >/dev/null 2>&1; then
    convert "$PKG/drone_controller.svg" -background none -resize 256x256 \
        PNG32:"$PKG/drone_controller.png"
fi
if [[ ! -f "$PKG/drone_controller.png" ]]; then
    echo "Error: packaging/drone_controller.png missing (and ImageMagick convert unavailable)."
    exit 1
fi

echo "=== Configuring Release build ==="
rm -rf "$APPDIR"
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "$BUILD" -j"$(nproc)"
DESTDIR="$APPDIR" cmake --install "$BUILD"

install -Dm644 "$PKG/drone_controller.desktop" \
    "$APPDIR/usr/share/applications/drone_controller.desktop"
# PNG only under hicolor — an SVG here makes linuxdeploy pick it and fail
install -Dm644 "$PKG/drone_controller.png" \
    "$APPDIR/usr/share/icons/hicolor/256x256/apps/drone_controller.png"
install -Dm644 "$PKG/drone_controller.png" \
    "$APPDIR/usr/share/icons/hicolor/128x128/apps/drone_controller.png"
install -Dm644 "$PKG/drone_controller.png" \
    "$APPDIR/usr/share/pixmaps/drone_controller.png"

echo "=== Bundling Qt + dependencies (AppDir) ==="
cd "$BUILD"
# Step 1: deploy libs/plugins/QML into AppDir (no AppImage yet)
"$TOOLS/linuxdeploy-x86_64.AppImage" \
    --appdir "$APPDIR" \
    --executable "$APPDIR/usr/bin/drone_controller" \
    --desktop-file "$APPDIR/usr/share/applications/drone_controller.desktop" \
    --icon-file "$PKG/drone_controller.png" \
    --plugin qt

# Step 2: force-copy transitive QML modules if the plugin skipped them
mkdir -p "$APPDIR/usr/qml"
rsync -a --delete "$QML_ROOT/QtQml/" "$APPDIR/usr/qml/QtQml/"

# Pull shared-library deps of the newly copied QML plugins
"$TOOLS/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR"
echo "=== Creating AppImage ==="
"$TOOLS/linuxdeploy-x86_64.AppImage" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/usr/share/applications/drone_controller.desktop" \
    --icon-file "$PKG/drone_controller.png" \
    --output appimage

shopt -s nullglob
generated=("$BUILD"/Drone_Controller*.AppImage "$BUILD"/drone_controller*.AppImage)
if ((${#generated[@]} == 0)); then
    echo "Error: AppImage was not produced in $BUILD"
    ls -la "$BUILD"
    exit 1
fi

mv -f "${generated[0]}" "$OUT"
echo
echo "OK: $OUT"
echo "Run with:  chmod +x \"$OUT\" && \"$OUT\""
