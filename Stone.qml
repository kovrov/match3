import QtQuick 2.4

Item {
    id: root
    property int type
    property var locked
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

    transform: Translate {
        id: tansl
    }

    Timer {
        id: crush_timer
        interval: 1000/30
        repeat: true
        onTriggered: {
            tansl.x = Math.random() * 6;
            tansl.y = Math.random() * 6;
        }
    }

    states: [
        State {
            name: "crush"
            PropertyChanges { target: crush_timer; running: true }
        }
    ]
}
