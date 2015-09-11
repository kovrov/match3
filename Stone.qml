import QtQuick 2.4
import "style.js" as Style

Item {
    id: root
    property int type
    property var locked
    readonly property bool moving: ax.running || ay.running

    Behavior on x { NumberAnimation { id: ax } }
    Behavior on y { NumberAnimation { id: ay } }

    ShaderEffect {
        anchors.centerIn: parent
        width: 60; height: 60

        property var mask: Image { source: Style.stones[root.type].mask }
        property color color: Style.stones[root.type].color

        fragmentShader: "#version 120
            varying highp vec2 qt_TexCoord0;
            uniform lowp float qt_Opacity;
            uniform sampler2D mask;
            uniform lowp vec4 color;
            void main() {
                vec4 mask_tex = texture2D(mask, qt_TexCoord0.st);
                vec4 color_tex = vec4(color.rgb, mask_tex.a);
                gl_FragColor =  color_tex * mask_tex.a * qt_Opacity;
            }"
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
