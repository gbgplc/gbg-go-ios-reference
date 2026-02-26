# Companion Server

A minimal Express server that creates GBG Go journey sessions using the Core SDK (`@gbg/go-core`). The iOS reference app calls this server to obtain a journey URL.

## Prerequisites

- **Node.js 18+**
- **GBG Go API credentials** — obtain from your GBG account representative or the GBG Go portal

## Setup

```bash
npm install
cp .env.example .env
```

Edit `.env` with your credentials:

| Variable | Description |
|----------|-------------|
| `GO_CLIENT_ID` | Your GBG Go client ID |
| `GO_CLIENT_SECRET` | Your GBG Go client secret |
| `GO_USERNAME` | API username (email) |
| `GO_PASSWORD` | API password |
| `GO_SERVER_IDX` | Regional server: `0` = EU, `1` = US, `2` = AU |
| `PORT` | Server port (default: `3000`) |

## Running

```bash
node index.mjs
```

The server authenticates with GBG Go on startup and listens for requests.

## Endpoints

### `GET /`

Returns server status:

```json
{
  "service": "gbg-go-reference-server",
  "status": "running",
  "region": "EU",
  "authenticated": true
}
```

### `GET /health`

Health check:

```json
{ "ok": true }
```

### `POST /api/journey/start`

Creates a new journey session and returns the URL for the iOS app to load.

**Request body** (all fields optional):

```json
{
  "resourceId": "a4c68509c24789888eb466@latest",
  "identity": {
    "firstName": "John",
    "lastNames": ["Doe"],
    "dateOfBirth": "1990-01-01"
  }
}
```

**Response:**

```json
{
  "instanceId": "PiIuACmx8Q8R7qPnAkLAqBAT",
  "journeyUrl": "https://...",
  "connectToken": "s4FUx8Ny8ijXRtFigz3x1_8rb9bd_5ZD",
  "expiresIn": 120
}
```

The `journeyUrl` is what the iOS app loads in its `BridgeWebView`. The `connectToken` is short-lived (typically 120 seconds).

## Connecting from iOS Simulator

When running the iOS app in the Simulator, `http://localhost:3000` works directly. When running on a physical device, use your Mac's local IP address (e.g., `http://192.168.1.100:3000`).
