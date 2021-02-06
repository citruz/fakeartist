// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

import {Socket} from "phoenix"
import "phoenix_html"

import LiveSocket from "phoenix_live_view"
import NProgress from "nprogress"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

let hooks = {
  canvas: {
    mounted() {
      canvas = this.el;
      initCanvas()
      connectToGame()
    }
  },
  chat: {
    updated() { 
      let div = this.el
      div.scrollTop = div.scrollHeight
    }
  },
  masterpiece: {
    mounted() {
      updateMasterpiece()
    },
    updated() {
      updateMasterpiece()
    }
  }
};
  
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: hooks});
liveSocket.connect();
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

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

let socket = undefined;
let channel = undefined;

function connectToGame() {
  let token = document.getElementById("game").dataset.token;
  socket = new Socket("/socket", {params: {token: window.userToken}})
  socket.connect()

  channel = socket.channel("draw:" + token);
  channel.join()
    .receive("ok", resp => { 
      console.log("Joined successfully", resp)
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
      channel.leave()
      if (resp == "game_not_started") {
        setTimeout(connectToGame, 1000)
      }
    })


  channel.on("draw", payload => {
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
}


function initCanvas() {
  ctx = canvas.getContext("2d");
  w = canvas.width;
  h = canvas.height;

  canvas.addEventListener("mousemove", function (e) {
    canvasHandler('move', e)
  }, false);
  canvas.addEventListener("touchmove", function (e) {
    canvasHandler('move', e)
  }, false);

  canvas.addEventListener("mousedown", function (e) {
    canvasHandler('down', e)
  }, false);
  canvas.addEventListener("touchstart", function (e) {
    canvasHandler('down', e)
  }, false);

  canvas.addEventListener("mouseup", function (e) {
    canvasHandler('up', e)
  }, false);
  canvas.addEventListener("touchend", function (e) {
    canvasHandler('up', e)
  }, false);

  canvas.addEventListener("mouseout", function (e) {
    canvasHandler('out', e)
  }, false);
  canvas.addEventListener("touchout", function (e) {
    canvasHandler('out', e)
  }, false);

  updateMasterpiece();

  var elems = document.getElementsByClassName("size-choose")
  Array.from(elems).forEach((el) => {
    el.addEventListener("click", function (e) {
      // set thickness
      thickness = el.dataset.thickness;
      // set selected class
      Array.from(elems).forEach((el) => {
        el.classList.remove("selected");
      });
      el.classList.add("selected");
    })
  });
}

function draw(fromX, fromY, toX, toY, color, thickness) {
  if (fromX == toX && fromY == toY) {
    // draw dot
    ctx.beginPath();
    ctx.fillStyle = color;
    ctx.arc(fromX, fromY, thickness / 2, 0, 2 * Math.PI, true);
    ctx.fill()
    ctx.closePath();
  } else {
    // draw line with dots at beginning and end
    ctx.beginPath();
    ctx.fillStyle = color;
    ctx.arc(fromX, fromY, thickness / 2, 0, 2 * Math.PI, true);
    ctx.fill();
    ctx.closePath();
    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = thickness;
    ctx.moveTo(fromX, fromY);
    ctx.lineTo(toX, toY);
    ctx.stroke();
    ctx.closePath();
    ctx.beginPath();
    ctx.arc(toX, toY, thickness / 2, 0, 2 * Math.PI, true);
    ctx.fill();
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

function recursiveOffsetLeftAndTop(element) {
  var offsetLeft = 0;
  var offsetTop = 0;
  while (element) {
      offsetLeft += element.offsetLeft;
      offsetTop += element.offsetTop;
      element = element.offsetParent;
  }
  return {
      offsetLeft: offsetLeft,
      offsetTop: offsetTop
  };
};

function canvasHandler(res, e) {
  e.preventDefault();
  prevX = currX;
  prevY = currY;

  if (window.TouchEvent && e instanceof TouchEvent && e.touches[0]) {
    let offsets = recursiveOffsetLeftAndTop(canvas);
    currX = e.touches[0].pageX - offsets.offsetLeft
    currY = e.touches[0].pageY - offsets.offsetTop
  } else {
    currX = e.layerX - canvas.offsetLeft
    currY = e.layerY - canvas.offsetTop
  }
  //console.log(`curx: ${currX} cury: ${currY}`)
  if (res == 'down') {
    mouseDown = true;
    sendDraw(currX, currY, currX, currY);
  }
  if (res == 'up' || res == "out") {
    mouseDown = false;
  }
  if (res == 'move' && mouseDown) {
    sendDraw(prevX, prevY, currX, currY);
  }
}

function updateMasterpiece() {
  let img_el = document.getElementById("masterpiece");
  if (canvas && img_el) {
    img_el.src = canvas.toDataURL("image/png")
    let link = document.getElementById("masterpiece-link")
    if (link) {
      link.href = canvas.toDataURL("image/png")
    }
  }
}