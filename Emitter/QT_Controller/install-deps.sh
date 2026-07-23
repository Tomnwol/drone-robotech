#!/usr/bin/env bash
# Installs build dependencies for drone_controller (Qt6 + evdev)
# Supports apt (Debian/Ubuntu) and dnf (Fedora/RHEL/CentOS)

set -euo pipefail

echo "=== Detecting package manager ==="

if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
else
    echo "Error: no supported package manager found (apt/dnf/yum)."
    exit 1
fi

echo "Detected package manager: $PM"
echo

# Pick the first package name that exists in the apt cache.
apt_pick() {
    local candidate
    for candidate in "$@"; do
        if apt-cache show "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    echo "Error: none of these packages are available: $*" >&2
    return 1
}

case "$PM" in
    apt)
        if command -v add-apt-repository >/dev/null 2>&1; then
            sudo add-apt-repository -y universe || true
        fi
        # Third-party repos (Docker, Espressif, …) may warn; ignore non-fatal noise.
        sudo apt-get update || true

        # Debian Trixie+: qml6-module-qtquick3d
        # Older Ubuntu:    qml6-module-quick3d
        QML_QUICK3D="$(apt_pick qml6-module-qtquick3d qml6-module-quick3d)"
        echo "Using Quick3D QML package: $QML_QUICK3D"

        sudo apt-get install -y \
            build-essential \
            cmake \
            pkg-config \
            qt6-base-dev \
            qt6-declarative-dev \
            qt6-quick3d-dev \
            qt6-shadertools-dev \
            qt6-serialport-dev \
            qml6-module-qtquick \
            qml6-module-qtquick-controls \
            "$QML_QUICK3D" \
            qml6-module-qtqml \
            qml6-module-qtqml-models \
            qml6-module-qtqml-workerscript \
            libevdev-dev
        ;;

    dnf)
        sudo dnf install -y \
            gcc-c++ \
            make \
            cmake \
            pkgconf-pkg-config \
            qt6-qtbase-devel \
            qt6-qtdeclarative-devel \
            qt6-qtquick3d-devel \
            qt6-qtshadertools-devel \
            qt6-qtserialport-devel \
            libevdev-devel
        ;;

    yum)
        sudo yum install -y \
            gcc-c++ \
            make \
            cmake \
            pkgconfig \
            qt6-qtbase-devel \
            qt6-qtdeclarative-devel \
            qt6-qtquick3d-devel \
            qt6-qtshadertools-devel \
            qt6-qtserialport-devel \
            libevdev-devel
        ;;
esac

echo
echo "=== Verifying via pkg-config ==="
MODULES="Qt6Widgets Qt6SerialPort Qt6Network Qt6Quick Qt6QuickWidgets Qt6Quick3D libevdev"
MISSING=0

for mod in $MODULES; do
    if pkg-config --exists "$mod"; then
        version=$(pkg-config --modversion "$mod")
        echo "  OK  $mod ($version)"
    else
        echo "  MISSING  $mod"
        MISSING=1
    fi
done

echo
if [ "$MISSING" -eq 0 ]; then
    echo "All dependencies are present."
    echo
    echo "Build:"
    echo "  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release"
    echo "  cmake --build build -j\$(nproc)"
    echo "  ./build/drone_controller"
else
    echo "Some modules are still missing. Check the package names for your"
    echo "distribution (they can vary between Ubuntu/Fedora/Debian versions)."
    exit 1
fi
