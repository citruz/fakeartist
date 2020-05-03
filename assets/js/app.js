// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

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

var player_idx = -1;

let socket = undefined;

let channel = undefined;
let privateChannel = undefined;
let messagesContainer = document.querySelector("#messages")

initCanvas()

if (window.gameToken) {
    socket = new Socket("/socket", {params: {token: window.userToken}})
    socket.connect()

    connectToGame(window.gameToken)
}

function connectToGame(token) {
    channel = socket.channel("game:" + token);
    channel.join()
        .receive("ok", resp => { 
            console.log("Joined successfully", resp)
            player_idx = resp.player_idx
        })
        .receive("error", resp => {
            addMessage(`failed to join game (reason: ${resp.error})`)
            console.log("Unable to join", resp)
            channel.leave()
        })


    channel.on("draw", payload => {
        if (payload.type == "clear") {
            clear();
        } else if (payload.type == "draw") {
            draw(payload.fromX, payload.fromY, payload.toX, payload.toY, payload.color, payload.thickness)
        }
    })

    channel.on("player:joined", payload => {
        addMessage(`${payload.player} joined`)
    })

    channel.on("game:state", payload => {
        console.log("new state: ", payload)
        updatePlayerList(payload)
        updateGameState(payload)
    })

    channel.on("clear", () => {
        console.log("clear")
        clear()
    })

    // connect to private channel
    privateChannel = socket.channel("user:" + window.userId);
    privateChannel.join()
        .receive("ok", resp => { 
            console.log("Joined private channel successfully", resp)
        })
        .receive("error", resp => {
            console.log("Unable to join private channel", resp)
        })

    privateChannel.on("select_category", () => {
        let category = prompt("Please enter a category")
        let subject = prompt("Please enter a subject")
        channel.push("select_category", {"category": category, "subject": subject})
    })

    privateChannel.on("subject", (payload) => {
        updateSubject(payload.subject)
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

    /*var elems = document.getElementsByClassName("color-chooser")[0].children
    Array.from(elems).forEach((el) => {
        el.addEventListener("click", function (e) {
            setColor(el);
        })
    });

    document.getElementById("clear").addEventListener("click", function (e) {
        sendClear();
    }); */
}

function updatePlayerList(state) {
    let players = state.players
    var list = document.getElementById('user-list');

    var child = list.lastElementChild;  
    while (child) { 
        list.removeChild(child); 
        child = list.lastElementChild; 
    }

    players.forEach(function(player, i) {
        var li = document.createElement('li');
        li.innerHTML = `<span class="color" style="background-color: ${player.color}">&nbsp;&nbsp;</span> ${player.name}`
        if (player.question_master) {
            li.innerHTML += " 👑"
        }
        if (i === state.current_player) {
            li.innerHTML += " ✏️"
        }
        list.appendChild(li);
    })
}

function updateGameState(infos) {
    let state = infos.state
    var state_div = document.getElementById('state')
    state_div.innerHTML = state;

    if (state == "initialized") {
        state_div.innerHTML += "<br /> Waiting for other players..."
    } else if (state == "ready") {
        var btn = document.createElement('button');
        btn.innerHTML = "Start Game"
        btn.addEventListener('click', function() {
            startGame();
        });
        state_div.appendChild(btn);
    } else if (state == "drawing") {
        state_div.innerHTML += `<br />Category: ${infos.category}`
        if (infos.current_player == player_idx) {
            var btn = document.createElement('button');
            btn.innerHTML = "Next"
            btn.addEventListener('click', function() {
                nextTurn();
            });
            state_div.appendChild(btn);
        }
    }
}

function updateSubject(category) {
    var elem = document.getElementById('category')
    elem.innerHTML = `Subject: ${category}`;
}

function startGame() {
    channel.push("start_game")
}

function nextTurn() {
    channel.push("next_turn")
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
    channel.push("draw", {
        type: "draw",
        fromX: fromX,
        fromY: fromY,
        toX: toX,
        toY: toY,
        thickness: thickness,
    })
}

function clear() {
    ctx.clearRect(0, 0, w, h);
}
function sendClear() {
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