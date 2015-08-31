import QtQuick 2.4
import QtQuick.Window 2.2

Window {
    visible: true
    width: 64 * 8; height: 64 * 8

    function updateColumn(col) {
        for (var row = 7 ; row >= 0; --row) {
            var index = row * 8 + col;
            var dest = grid.children[index];
            if (!dest.stone) {
                var above = grid.children[(row - 1) * 8 + col];
                var stone = above && above.stone ||
                        stoneComponent.createObject(board, {x: dest.x, y: -64});
                dest.stone = stone;
                stone.y = dest.y;
                if (above) above.stone = null;
            }
        }
    }

    Item {
        id: board
        Grid {
            id: grid
            rows: 8; columns: 8
            Repeater {
                model: 8 * 8
                Item {
                    id: delegate
                    readonly property int row: Math.floor(model.index / 8)
                    readonly property int column: model.index % 8
                    property Item stone
                    width: 64; height: 64
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            delegate.stone.destroy();
                            delegate.stone = null;
                            updateColumn(delegate.column);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: stoneComponent
        Rectangle {
            width: 64; height: 64
            color: Qt.hsla(Math.random(), 0.5, 0.5)
            Behavior on y { NumberAnimation {} }
        }
    }

    Component.onCompleted: {
        for (var i=0; i < 8; ++i) {
            updateColumn(i);
        }
    }
}
