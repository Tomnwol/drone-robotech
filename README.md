# Robotech Drone — 2025/2026

ESP32-based 5" drone built by the Robotech team. Attitude is estimated from a 9-axis IMU, then converted into motor commands through a PID loop. Control and telemetry go over the ESP32's built-in Wi-Fi (UDP).

## Approach

A 9-axis IMU (accelerometer, gyroscope, magnetometer) feeds a Madgwick AHRS filter to estimate attitude. Angular commands from that estimate drive the motors via DShot.

## Components

| Part         | Model                                      |
| ------------ | ------------------------------------------ |
| MCU          | ESP32 DevKit                               |
| Accel / Gyro | MPU-9265                                   |
| Magnetometer | GY-271 *(not-used)*                        |
| Motors       | XING-E Pro 2207 1800KV 2–6S (iFlight)      |
| ESC          | Hobbywing XRotor Micro 65A G2 4-in-1 AM32  |
| Battery      | LiPo GNB 6S 2200 mAh 120C — XT60 (Gaoneng) |
| Link         | ESP32 Wi-Fi (UDP)                          |
| Frame        | Designed in Fusion 360, 3D-printed         |
| PCB          | Designed in KiCad 9                        |

## Firmware

After library issues with DShot under ESP-IDF / PlatformIO, the flight code moved to **Arduino IDE** to use a more recent **DSHOTRMT** build. Firmware lives under `main/`.

## Ground station (Qt)

A Qt 6 ground station in `Emitter/QT_Controller/` connects over Wi-Fi and sends stick / config commands by UDP.

### If you just want to run it (nothing to install)

On Linux **x86_64**, take the portable AppImage (from a release or built by someone else). Qt and libraries are already bundled — you do **not** need to install cmake, Qt, or run `install-deps.sh`.

```bash
chmod +x drone_controller-x86_64.AppImage
./drone_controller-x86_64.AppImage
```

PID / motor offsets are saved under `~/.config/drone_controller/initialValues.ini`.

An Xbox-style gamepad named `Generic X-Box pad` is optional; without it the UI still starts (sticks can be moved with the on-screen sliders).

### If you want to build from source (developers)

You need a package manager (`apt` / `dnf` / `yum`). From a clean machine:

```bash
git clone <repo-url>
cd drone-robotech/Emitter/QT_Controller

./install-deps.sh   # cmake, g++, Qt6, QML modules, libevdev, …

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
./build/drone_controller
```

Use **CMake + Qt6 only** — do not use `qmake` / Qt5 (`qmake` on Ubuntu often points to Qt5).

To produce the AppImage yourself (after the steps above):

```bash
./packaging/build-appimage.sh
./drone_controller-x86_64.AppImage
```

| Who | What to do |
| --- | --- |
| End user | Run the `.AppImage` |
| Contributor / packager | `install-deps.sh` → cmake build → optional `build-appimage.sh` |

## Simulation

`Simulation/simulation.py` visualizes attitude estimation and the four motor responses so PID gains can be tuned offline.

## Media

![Drone hardware](Videos/drone-hardware.jpg)

<video src="Videos/20260323_190743.mp4" controls width="720"></video>

<video src="Videos/20260323_191418.mp4" controls width="720"></video>
