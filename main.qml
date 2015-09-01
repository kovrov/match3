import QtQuick 2.4
import QtQuick.Window 2.2

Window {
    visible: true
    width: 64 * 8; height: 64 * 8
    color: "#333"

    function index(col, row) {
        return col >= 0 && col < 8 && row >= 0 && row < 8 ? col + row * 8 : -1;
    }

    function remove(stone) {
        stone.square.stone = null;
        stone.destroy();
        updateColumn(stone.square.column);
    }

    function swap(stone_a, stone_b) {
        var square_a = stone_a.square, square_b = stone_b.square
        stone_a.square = square_b;
        stone_b.square = square_a;
    }

    function updateColumn(col) {
        for (var row = 7 ; row >= 0; --row) {
            var square = grid.children[index(col, row)];
            if (!square.stone) {
                var above = grid.children[index(col, row - 1)];
                var stone = above && above.stone ||
                        stoneComponent.createObject(board, {x: square.x, y: -64});
                stone.square = square;
                if (above)
                    above.stone = null;
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
                    // square
                    readonly property int row: Math.floor(model.index / 8)
                    readonly property int column: model.index % 8
                    property Item stone
                    width: 64; height: 64
                }
            }
        }
    }

    Component {
        id: stoneComponent
        Rectangle {
            id: stone
            property Item square
            width: 64; height: 64
            color: Qt.hsla(Math.floor(Math.random() * 7) / 7, 0.5, 0.5)
            enabled: !(ax.running || ay.running)

            onSquareChanged: {
                square.stone = stone;
                x = square.x;
                y = square.y;
            }

            Behavior on x { NumberAnimation { id: ax } }
            Behavior on y { NumberAnimation { id: ay } }

            MouseArea {
                anchors.fill: parent
                onExited: {
                    var other;
                    if (mouseX < 0) {
                        other = grid.children[index(stone.square.column - 1, stone.square.row)];
                    } else if (mouseX > width) {
                        other = grid.children[index(stone.square.column + 1, stone.square.row)];
                    } else if (mouseY < 0) {
                        other = grid.children[index(stone.square.column, stone.square.row - 1)];
                    } else if (mouseY > height) {
                        other = grid.children[index(stone.square.column, stone.square.row + 1)];
                    }
                    if (other && other.stone)
                        swap(stone, other.stone);
                }
            }
        }
    }

    Component.onCompleted: {
        for (var i=0; i < 8; ++i) {
            updateColumn(i);
        }
    }
}
