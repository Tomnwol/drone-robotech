import QtQuick
import QtQuick3D

Item {
    id: root
    width: 200
    height: 200

    property real orientYaw: 0
    property real orientRoll: 0
    property real orientPitch: 0

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#434c5e"
        border.width: 2
        radius: 4
        z: 1
    }

    View3D {
        anchors.fill: parent
        z: 0
        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#303030"
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 0, 400)
        }

        DirectionalLight {
            eulerRotation.x: -45
        }

        Model {
            source: "#Cube"
            scale: Qt.vector3d(2, 0.5, 2)
            // Bound once at load; updated via root properties from C++.
            eulerRotation.x: root.orientPitch
            eulerRotation.y: root.orientYaw
            eulerRotation.z: root.orientRoll
            materials: DefaultMaterial {
                diffuseColor: "#5E85B5"
            }
        }
    }
}
