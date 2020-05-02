// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import {Socket} from "phoenix"
import "phoenix_html"

var canvas
var ctx
var mouseDown = false
var prevX = 0
var currX = 0
var prevY = 0
var currY = 0
var w = 0
var h = 0

var color = "black"
var thickness = 2;

let socket = new Socket("/socket", {params: {token: window.userToken}})
socket.connect()

let channel = undefined;
let messagesContainer = document.querySelector("#messages")


const urlParams = new URLSearchParams(window.location.search);

document.getElementById("join").addEventListener("click", function(e) {
    let token = document.getElementById("token").value
    if (token) {
        connectToGame(token)
    }
});



function connectToGame(token) {
    channel = socket.channel("game:" + token);

    channel.on("draw", payload => {
        console.log("draw: ", payload);
        if (payload.type == "clear") {
            clear();
        } else if (payload.type == "draw") {
            draw(payload.fromX, payload.fromY, payload.toX, payload.toY, payload.color, payload.thickness)
        }
    })

    channel.on("clear", () => {
        console.log("clear")
        clear()
    })

    channel.join()
        .receive("ok", resp => { 
            addMessage(`joined game ${token}`)
            console.log("Joined successfully", resp)
            initCanvas();
        })
        .receive("error", resp => {
            addMessage(`failed to join game ${token}`)
            console.log("Unable to join", resp)
        })
}


function initCanvas() {
    canvas = document.getElementById('can');
    ctx = canvas.getContext("2d");
    w = canvas.width;
    h = canvas.height;

    canvas.addEventListener("mousemove", function (e) {
        canvasHandler('move', e)
    }, false);
    canvas.addEventListener("mousedown", function (e) {
        canvasHandler('down', e)
    }, false);
    canvas.addEventListener("mouseup", function (e) {
        canvasHandler('up', e)
    }, false);
    canvas.addEventListener("mouseout", function (e) {
        canvasHandler('out', e)
    }, false);

    var elems = document.getElementsByClassName("color-chooser")[0].children
    Array.from(elems).forEach((el) => {
        el.addEventListener("click", function (e) {
            setColor(el);
        })
    });

    document.getElementById("clear").addEventListener("click", function (e) {
        sendClear();
    }); 
}

function setColor(obj) {
    color = obj.id;
    if (color == "white") {
        thickness = 14;
    } else {
        thickness = 2;
    }
}

function draw(fromX, fromY, toX, toY, color, thickness) {
    if (fromX == toX && fromY == toY) {
        // draw dot
        ctx.beginPath();
        ctx.fillStyle = color;
        ctx.fillRect(currX, currY, 2, 2);
        ctx.closePath();
    } else {
        // draw line
        ctx.beginPath();
        ctx.moveTo(fromX, fromY);
        ctx.lineTo(toX, toY);
        ctx.strokeStyle = color;
        ctx.lineWidth = thickness;
        ctx.stroke();
        ctx.closePath();
    }
}

function sendDraw(fromX, fromY, toX, toY) {
    console.log("sendDraw: ", fromX, fromY, toX, toY);
    channel.push("draw", {
        type: "draw",
        fromX: fromX,
        fromY: fromY,
        toX: toX,
        toY: toY,
        color: color,
        thickness: thickness,
    })
}

function clear() {
    ctx.clearRect(0, 0, w, h);
}
function sendClear() {
    console.log("sendClear");
    channel.push("draw", { type: "clear" });
}

function canvasHandler(res, e) {
    if (res == 'down') {
        currX = e.layerX - canvas.offsetLeft;
        currY = e.layerY - canvas.offsetTop;

        mouseDown = true;
        sendDraw(currX, currY, currX, currY);
    }
    if (res == 'up' || res == "out") {
        mouseDown = false;
    }
    if (res == 'move' && mouseDown) {
        prevX = currX;
        prevY = currY;
        currX = e.layerX - canvas.offsetLeft;
        currY = e.layerY - canvas.offsetTop;
        sendDraw(prevX, prevY, currX, currY);
    }
}

function addMessage(msg) {
    let messageItem = document.createElement("p")
    let d = new Date()
    messageItem.innerText = `[${d.getHours()}:${d.getMinutes()}:${d.getSeconds()}] ${msg}`
    messagesContainer.appendChild(messageItem)
}