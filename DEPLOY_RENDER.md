# Deploy Web + WSS on Render

This project is prepared to deploy as a single Render web service:

- static web build served from `build/web`
- WebSocket relay served from `/ws`
- health check served from `/healthz`

## Files

- `render.yaml`
- `online_server/server.js`
- `online_server/package.json`

## Deploy steps

1. Push this repo to GitHub.
2. Create a Render account and connect the repo.
3. Create a new Blueprint on Render.
4. Render should detect `render.yaml`.
5. Approve the service creation.
6. Wait for the first deploy to finish.

## Result

Render gives you a URL like:

- `https://your-app.onrender.com`

The game page is served from:

- `https://your-app.onrender.com/`

The WebSocket endpoint is:

- `wss://your-app.onrender.com/ws`

The Godot web client auto-detects this URL when running on the web.

## Local run

From `online_server`:

```bash
npm install
npm start
```

Local endpoints:

- `http://127.0.0.1:8787/`
- `ws://127.0.0.1:8787/ws`
