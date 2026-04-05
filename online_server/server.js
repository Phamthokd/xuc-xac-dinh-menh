import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import WebSocket, { WebSocketServer } from "ws";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PORT = Number(process.env.PORT || 8787);
const WEB_ROOT = path.resolve(__dirname, "../build/web");
const rooms = new Map();

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".json": "application/json; charset=utf-8",
  ".js.map": "application/json; charset=utf-8",
  ".ico": "image/x-icon",
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  if (url.pathname === "/healthz") {
    res.writeHead(200, { "content-type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ ok: true }));
    return;
  }

  let relativePath = url.pathname === "/" ? "/index.html" : url.pathname;
  relativePath = relativePath.replace(/^\/+/, "");
  const filePath = path.resolve(WEB_ROOT, relativePath);
  if (!filePath.startsWith(WEB_ROOT)) {
    res.writeHead(403).end("Forbidden");
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404).end("Not Found");
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, {
      "content-type": MIME_TYPES[ext] || "application/octet-stream",
      "cache-control": "no-store, no-cache, must-revalidate",
      pragma: "no-cache",
      expires: "0",
    });
    res.end(data);
  });
});

const wss = new WebSocketServer({ server, path: "/ws" });

function send(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

function broadcast(room, payload, except = null) {
  for (const client of room.clients) {
    if (client !== except && client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(payload));
    }
  }
}

function ensureRoom(code) {
  if (!rooms.has(code)) {
    rooms.set(code, {
      code,
      host: null,
      clients: new Set(),
      state: null,
    });
  }
  return rooms.get(code);
}

function cleanupRoom(code) {
  const room = rooms.get(code);
  if (!room) return;
  if (!room.host && room.clients.size === 0) {
    rooms.delete(code);
  }
}

function logRoomEvent(roomCode, message) {
  console.log(`[room:${roomCode || "-"}] ${message}`);
}

wss.on("connection", (ws) => {
  ws.roomCode = "";
  ws.playerIndex = -1;
  ws.isHost = false;

  logRoomEvent("", "socket connected");

  ws.on("message", (raw) => {
    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      send(ws, { type: "error", message: "Invalid JSON payload." });
      return;
    }

    const type = String(message.type || "");
    if (!type) {
      send(ws, { type: "error", message: "Missing message type." });
      return;
    }

    if (type === "host_room") {
      const roomCode = String(message.room_code || "").trim().toUpperCase();
      if (!roomCode) {
        send(ws, { type: "error", message: "Room code is required." });
        return;
      }

      const room = ensureRoom(roomCode);
      room.host = ws;
      room.clients.add(ws);
      room.state = message.state || room.state;
      ws.roomCode = roomCode;
      ws.playerIndex = 0;
      ws.isHost = true;
      logRoomEvent(roomCode, "host registered");
      send(ws, { type: "room_hosted", room_code: roomCode, state: room.state });
      return;
    }

    if (type === "join_room") {
      const roomCode = String(message.room_code || "").trim().toUpperCase();
      const room = rooms.get(roomCode);
      if (!room || !room.host) {
        send(ws, { type: "error", message: "Room not found." });
        return;
      }

      ws.roomCode = roomCode;
      ws.playerIndex = Number(message.player_index ?? 1);
      ws.isHost = false;
      room.clients.add(ws);
      logRoomEvent(roomCode, `client joined as player ${ws.playerIndex}`);
      send(ws, { type: "room_joined", room_code: roomCode, state: room.state });
      broadcast(room, { type: "peer_joined", room_code: roomCode, player_index: ws.playerIndex }, ws);
      return;
    }

    if (!ws.roomCode) {
      send(ws, { type: "error", message: "Join a room first." });
      return;
    }

    const room = rooms.get(ws.roomCode);
    if (!room) {
      send(ws, { type: "error", message: "Room no longer exists." });
      return;
    }

    if (type === "state_update") {
      if (!ws.isHost) {
        send(ws, { type: "error", message: "Only the host can publish state." });
        return;
      }

      room.state = message.state || room.state;
      logRoomEvent(ws.roomCode, "state update broadcast");
      broadcast(room, { type: "state_update", room_code: ws.roomCode, state: room.state }, ws);
      return;
    }

    if (type === "roll_request") {
      if (!room.host) {
        send(ws, { type: "error", message: "Host is offline." });
        return;
      }

      logRoomEvent(ws.roomCode, `roll request from player ${Number(message.player ?? ws.playerIndex)}`);
      send(room.host, {
        type: "action_request",
        action: "roll_request",
        room_code: ws.roomCode,
        player: Number(message.player ?? ws.playerIndex),
        turn: Number(message.turn ?? 0),
        sender: Number(message.sender ?? ws.playerIndex),
      });
      return;
    }

    send(ws, { type: "error", message: `Unsupported message type: ${type}` });
  });

  ws.on("close", () => {
    logRoomEvent(ws.roomCode, ws.isHost ? "host disconnected" : `client ${ws.playerIndex} disconnected`);
    if (!ws.roomCode) return;
    const room = rooms.get(ws.roomCode);
    if (!room) return;

    room.clients.delete(ws);
    if (room.host === ws) {
      room.host = null;
      broadcast(room, { type: "error", message: "Host disconnected." });
    }
    cleanupRoom(ws.roomCode);
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`HTTP + WebSocket server listening on http://0.0.0.0:${PORT}`);
  console.log(`Serving static files from ${WEB_ROOT}`);
  console.log(`WebSocket endpoint available at /ws`);
});
