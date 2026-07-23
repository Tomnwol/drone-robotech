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

case "$PM" in
    apt)
        if command -v add-apt-repository >/dev/null 2>&1; then
            sudo add-apt-repository -y universe || true
        fi
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            cmake \
            pkg-config \
            curl \
            libfuse2 \
            imagemagick \
            rsync \
            qt6-base-dev \
            qt6-declarative-dev \
            qt6-quick3d-dev \
            qt6-shadertools-dev \
            qt6-serialport-dev \
            qml6-module-qtquick \
            qml6-module-qtquick-controls \
            qml6-module-quick3d \
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
            curl \
            fuse \
            ImageMagick \
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
            curl \
            fuse \
            ImageMagick \
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
    echo
    echo "AppImage:"
    echo "  ./packaging/build-appimage.sh"
else
    echo "Some modules are still missing. Check the package names for your"
    echo "distribution (they can vary between Ubuntu/Fedora versions)."
    exit 1
fi
