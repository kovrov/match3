import QtQuick 2.4
import QtQuick.Window 2.2
import "style.js" as Style

Window {
    visible: true


    signal score(int points)
    signal message(string text)

    width: Style.window.width; height: Style.window.height
    color: "#333"

    function getIndex(col, row) {
        return col >= 0 && col < 8 && row >= 0 && row < 8 ? col + row * 8 : -1;
    }

    function matchingSets(squares) {
        var hmap = {}, vmap = {}, groups = [];
        function add_to_group(idx, prev_idx, map) {
            var this_square = squares[idx], other_square = squares[prev_idx];
            if (!this_square.stone || this_square.stone.moving || this_square.stone.locked) {
                return;
            }
            if (other_square && other_square.stone &&
                    !other_square.stone.moving && !other_square.stone.locked &&
                    other_square.stone.type === this_square.stone.type) {
                map[idx] = map[prev_idx];
            } else {
                map[idx] = [];
                groups.push(map[idx]);
            }
            map[idx].push(idx);
        }
        for (var i = 0; i < squares.length; ++i) {
            var col = i % 8, row = Math.floor(i / 8);
            add_to_group(i, getIndex(col - 1, row), hmap, groups);
            add_to_group(i, getIndex(col, row - 1), vmap, groups);
        }
        return groups.filter(function(i) { return i.length > 2; });
    }

    function trySwap(idx_a, idx_b) {
        var square_a = grid.squares[idx_a], square_b = grid.squares[idx_b];
        var stone_a = square_a.stone, stone_b = square_b.stone;
        if (!stone_a || !stone_b || stone_a.locked || stone_b.locked || stone_a.moving || stone_b.moving) {
            return;
        }
        var squares = grid.squares.slice();
        squares[idx_a] = square_b;
        squares[idx_b] = square_a;
        var m = matchingSets(squares);
        var set_a = m.filter(function(m) { return m.indexOf(idx_a) !== -1; }).reduce(function(a, r) { return r.concat(a); }, []);
        var set_b = m.filter(function(m) { return m.indexOf(idx_b) !== -1; }).reduce(function(a, r) { return r.concat(a); }, []);
        if (set_a.length || set_b.length) {
            square_a.stone = stone_b;
            square_b.stone = stone_a;
            set_a.combo = set_b.combo = Math.max(0, set_a.length - 2) + Math.max(0, set_b.length - 2);
            for (var i = 0; i < set_a.length; ++i) {
                grid.squares[set_a[i]].stone.locked = set_a;
            }
            for (var i = 0; i < set_b.length; ++i) {
                grid.squares[set_b[i]].stone.locked = set_b;
            }
        }
    }

    function getAbove(col, row) {
        for (var i = row - 1; i >= 0; --i) {
            var square = grid.squares[getIndex(col, i)];
            if (square.stone) {
                return square;
            }
        }
        return null;
    }

    function updateColumn(col) {
        for (var row = 7 ; row >= 0; --row) {
            var square = grid.squares[getIndex(col, row)];
            if (square.stone) {
                continue;
            }
            var square_above = getAbove(col, row);
            if (square_above) {
                if (square_above.stone.locked) {
                    continue;
                }
                square.stone = square_above.stone; // this will trigger animation
                square_above.stone = null;
            } else {
                // FIXME
                square.stone = stoneComponent.createObject(board, {
                                                               x: square.x, y: -64,
                                                               type: Math.floor(Math.random() * 7)
                                                           });
            }
        }
    }

    Item {
        id: board
        Grid {
            id: grid
            z: 1

            property var squares: []
            rows: 8; columns: 8
            Repeater {
                model: 8 * 8
                Item {
                    id: square
                    readonly property int row: Math.floor(model.index / 8)
                    readonly property int column: model.index % 8
                    property Item stone

                    function kill(locked) {
                        if (stone) {
                            stone.locked = locked;
                            killTimer.running = true;
                        }
                    }

                    width: Style.tile.width; height: Style.tile.height
                    enabled: stone && !stone.moving

                    Component.onCompleted: { grid.squares[model.index] = this; }

                    onStoneChanged: {
                        if (stone) {
                            stone.x = x;
                            stone.y = y;
                        } else {
                            updateColumn(column);
                        }
                    }

                    onEnabledChanged: {
                        if (enabled) {
                            updateColumn(column);
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        visible: enabled
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
                            if (other_idx !== -1) {
                                trySwap(model.index, other_idx);
                            }
                        }
                    }

                    Timer {
                        id: killTimer
                        interval: Style.ani.removeDelay
                        onRunningChanged: {
                            if (running) {
                                square.stone.state = "crush";
                            } else {
                                square.stone.destroy();
                                square.stone = null;
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: stoneComponent

        Stone {
            width: Style.tile.width; height: Style.tile.height
            onMovingChanged: {
                if (!moving) {
                    if (locked) {
                        locked.forEach(function(idx, index, locked) {
                            grid.squares[idx].kill(locked);
                        });
                        if (locked.combo !== 1)
                            message("X" + locked.combo + "!")
                        score(locked.length * locked.combo);
                        return;
                    }
                    updateTimer.restart();
                }
            }
        }
    }

    Component.onCompleted: {
        for (var i = 0; i < 8; ++i) {
            updateColumn(i);
        }
    }

    Timer {
        id: updateTimer
        interval: 1000 / 30
        onTriggered: {
            var sets = matchingSets(grid.squares);
            if (sets.length > 1)
                message("x" + sets.length + "!");
            for (var i = 0; i < sets.length; ++i) {
                var matches = sets[i];
                for (var j = 0; j < matches.length; ++j) {
                    grid.squares[matches[j]].kill(matches);
                }
                score(matches.length * sets.length);
            }
        }
    }
}
