import QtQuick 2.4
import QtQuick.Window 2.2

Window {
    visible: true
    width: 64 * 8; height: 64 * 8
    color: "#333"

    function getIndex(col, row) {
        return col >= 0 && col < 8 && row >= 0 && row < 8 ? col + row * 8 : -1;
    }

    function removeSquare(square) {
        square.stone.destroy();
        square.stone = null;
        updateColumn(square.column);
    }

    function swapSquares(square_a, square_b) {
        var stone_a = square_a.stone, stone_b = square_b.stone;
        square_a.stone = stone_b;
        square_b.stone = stone_a;
    }

    function updateColumn(col) {
        for (var row = 7 ; row >= 0; --row) {
            var square = grid.children[getIndex(col, row)];
            if (!square.stone) {
                var above = grid.children[getIndex(col, row - 1)];
                var stone = above && above.stone ||
                        stoneComponent.createObject(board, {x: square.x, y: -64});
                square.stone = stone; // this will trigger animation
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
                MouseArea {
                    // square
                    readonly property int row: Math.floor(model.index / 8)
                    readonly property int column: model.index % 8
                    property Item stone
                    width: 64; height: 64
                    enabled: stone && !stone.moving

                    onStoneChanged: {
                        if (stone) {
                            stone.x = x;
                            stone.y = y;
                        }
                    }
                    onExited: {
                        var other;
                        if (mouseX < 0) {
                            other = grid.children[getIndex(column - 1, row)];
                        } else if (mouseX > width) {
                            other = grid.children[getIndex(column + 1, row)];
                        } else if (mouseY < 0) {
                            other = grid.children[getIndex(column, row - 1)];
                        } else if (mouseY > height) {
                            other = grid.children[getIndex(column, row + 1)];
                        }
                        if (other && other.stone)
                            swapSquares(this, other);
                    }
                }
            }
        }
    }

    Component {
        id: stoneComponent
        Rectangle {
            id: stone
            width: 64; height: 64
            color: Qt.hsla(Math.floor(Math.random() * 7) / 7, 0.5, 0.5)

            Behavior on x { NumberAnimation { id: ax } }
            Behavior on y { NumberAnimation { id: ay } }
        }
    }

    Component.onCompleted: {
        for (var i=0; i < 8; ++i) {
            updateColumn(i);
        }
    }
}
