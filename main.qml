import QtQuick 2.4
import QtQuick.Window 2.2
import "style.js" as Style

Window {
    visible: true
    width: Style.window.width; height: Style.window.height
    color: "#333"

    function getIndex(col, row) {
        return col >= 0 && col < 8 && row >= 0 && row < 8 ? col + row * 8 : -1;
    }

    function removeSquare(square) {
        square.stone.destroy();
        square.stone = null;
        updateColumn(square.column);
    }

    function matchingSets(list) {
        var hmap = {};
        var vmap = {};
        var groups = [];
        function add_to_group(idx, prev_idx, map) {
            var type = list[idx].stone.type;
            if (prev_idx !== -1 && list[prev_idx] && list[prev_idx].stone.type === type) {
                map[idx] = map[prev_idx];
            } else {
                map[idx] = [];
                groups.push(map[idx]);
            }
            map[idx].push(idx);
        }
        for (var i = 0; i < list.length; ++i) {
            var col = i % 8, row = Math.floor(i / 8);
            add_to_group(i, getIndex(col - 1, row), hmap, groups);
            add_to_group(i, getIndex(col, row - 1), vmap, groups);
        }
        return groups.filter(function(i) { return i.length > 2; });
    }

    function isSwappable(idx_a, idx_b) {
        var squares = grid.squares.slice();
        var a = squares[idx_a], b = squares[idx_b];
        squares[idx_a] = b;
        squares[idx_b] = a;
        var m = matchingSets(squares).reduce(function(a, r) { return r.concat(a); }, []);
        return m.indexOf(idx_a) !== -1 || m.indexOf(idx_b) !== -1;
    }

    function swapSquares(square_a, square_b) {
        var stone_a = square_a.stone, stone_b = square_b.stone;
        square_a.stone = stone_b;
        square_b.stone = stone_a;
    }

    function updateColumn(col) {
        for (var row = 7 ; row >= 0; --row) {
            var square = grid.squares[getIndex(col, row)];
            if (!square.stone) {
                var above = grid.squares[getIndex(col, row - 1)];
                var stone = above && above.stone ||
                        stoneComponent.createObject(board, {
                                                        x: square.x, y: -64,
                                                        type: Math.floor(Math.random() * 7)
                                                    });
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

            property var squares: []
            rows: 8; columns: 8
            Repeater {
                model: 8 * 8
                MouseArea {
                    // square
                    readonly property int row: Math.floor(model.index / 8)
                    readonly property int column: model.index % 8
                    property Item stone

                    width: Style.tile.width; height: Style.tile.height
                    enabled: stone && !stone.moving

                    Component.onCompleted: { grid.squares[model.index] = this; }

                    onStoneChanged: {
                        if (stone) {
                            stone.x = x;
                            stone.y = y;
                        }
                    }

                    onExited: {
                        var other_idx = -1;
                        if (mouseX < 0) {
                            other_idx = getIndex(column - 1, row);
                        } else if (mouseX > width) {
                            other_idx = getIndex(column + 1, row);
                        } else if (mouseY < 0) {
                            other_idx = getIndex(column, row - 1);
                        } else if (mouseY > height) {
                            other_idx = getIndex(column, row + 1);
                        }
                        if (other_idx !== -1 && isSwappable(model.index, other_idx)) {
                            swapSquares(this, grid.squares[other_idx]);
                        }
                    }
                }
            }
        }
    }

    Component {
        id: stoneComponent

        Item {
            // stone
            property int type
            readonly property bool moving: ax.running || ay.running
            width: Style.tile.width; height: Style.tile.height

            onMovingChanged: {
                if (!moving) {
                    var sets = matchingSets(grid.squares);
                    for (var i = 0; i < sets.length; ++i) {
                        var matches = sets[i];
                        if (matches.every(function(k) { return grid.squares[k].stone && !grid.squares[k].stone.moving; })) {
                            for (var j = 0; j < matches.length; ++j) {
                                removeSquare(grid.squares[matches[j]]);
                            }
                        }
                    }
                }
            }

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
    }

    Component.onCompleted: {
        for (var i = 0; i < 8; ++i) {
            updateColumn(i);
        }
    }
}
