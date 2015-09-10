import QtQuick 2.4

Item {
    id: root
    readonly property bool moving: ax.running || ay.running

    Behavior on x { NumberAnimation { id: ax } }
    Behavior on y { NumberAnimation { id: ay } }

    Rectangle {
        anchors.centerIn: parent
        width: 48; height: 48; radius: 24
        color: Qt.hsla(type / 7,
                       type === 3 ? 0 : 0.5,
                       type === 3 ? 0.6 : 0.5)
    }
}
