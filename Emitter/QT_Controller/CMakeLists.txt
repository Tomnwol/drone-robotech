cmake_minimum_required(VERSION 3.16)

project(drone_controller VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

add_compile_options(-Wall -Wextra)

find_package(Qt6 REQUIRED COMPONENTS
    Widgets
    SerialPort
    Network
    Quick
    QuickWidgets
    Quick3D
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(EVDEV REQUIRED IMPORTED_TARGET libevdev)

set(SOURCES
    CSV.cpp
    UDP.cpp
    configuration.cpp
    controller.cpp
    qtBoxConfiguration.cpp
    qtControllerBox.cpp
    qtDroneBox.cpp
    qtStartBox.cpp
    qtStyles.cpp
    qt_drone_controller.cpp
    wifiConnection.cpp
)

set(HEADERS
    CSV.hpp
    UDP.hpp
    configuration.hpp
    controller.hpp
    qtBoxConfiguration.hpp
    qtControllerBox.hpp
    qtDroneBox.hpp
    qtStartBox.hpp
    qtStyles.hpp
)

qt_add_executable(drone_controller
    ${SOURCES}
    ${HEADERS}
    resources.qrc
)

target_link_libraries(drone_controller PRIVATE
    Qt6::Widgets
    Qt6::SerialPort
    Qt6::Network
    Qt6::Quick
    Qt6::QuickWidgets
    Qt6::Quick3D
    PkgConfig::EVDEV
)

install(TARGETS drone_controller RUNTIME DESTINATION bin)
