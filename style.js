.pragma library

var grid = {
    size: 8
};

var tile = {
    width: 60,
    height: 60
};

var window = {
    width: grid.size * tile.width,
    height: grid.size * tile.height
};

var ani = {
    removeDelay: 500
};

var stones = [
            { color: "#d46", mask: "circle.png" },
            { color: "#079", mask: "squircle.png" },
            { color: "#39f", mask: "hex.png" },
            { color: "#4c5", mask: "octa.png" },
            { color: "#bc0", mask: "poly.png" },
            { color: "#a49", mask: "square2.png" },
            { color: "#aaa", mask: "square.png" },
        ];
