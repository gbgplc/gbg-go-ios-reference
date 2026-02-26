/**
 * GBG Go Reference — Companion Server
 *
 * A minimal Express server that demonstrates how to create journey sessions
 * using the GBG Go Core SDK (@gbg/go-core). The iOS reference app calls this
 * server to obtain a journey URL, which it then loads in a BridgeWebView.
 *
 * Flow:
 *   1. On startup, the server authenticates with GBG Go using your credentials.
 *   2. POST /api/journey/start creates a new journey session and returns the URL.
 *   3. The iOS app receives the URL and loads it in its WKWebView.
 *
 * Usage:
 *   cp .env.example .env   # Fill in your GBG Go credentials
 *   npm install
 *   node index.mjs
 */

import "dotenv/config";
import express from "express";
import { Go } from "@gbg/go-core";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const SERVER_IDX = parseInt(process.env.GO_SERVER_IDX || "0", 10);
const REGIONS = ["EU", "US", "AU"];

// ---------------------------------------------------------------------------
// Authentication — generate an access token on startup
// ---------------------------------------------------------------------------

let customerAccessToken = null;

async function authenticate() {
  const go = new Go();
  const auth = await go.tokens.generate({
    clientId: process.env.GO_CLIENT_ID,
    clientSecret: process.env.GO_CLIENT_SECRET,
    username: process.env.GO_USERNAME,
    password: process.env.GO_PASSWORD,
    grantType: "password",
  });
  customerAccessToken = auth.accessToken;
  console.log(`Authenticated with GBG Go (${REGIONS[SERVER_IDX]} region)`);
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

/** GET / — server status */
app.get("/", (_req, res) => {
  res.json({
    service: "gbg-go-reference-server",
    status: "running",
    region: REGIONS[SERVER_IDX],
    authenticated: customerAccessToken !== null,
  });
});

/** GET /health — health check */
app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

/**
 * POST /api/journey/start — create a new journey session
 *
 * Request body (all fields optional):
 *   {
 *     "resourceId": "a4c68509c24789888eb466@latest",
 *     "identity": { "firstName": "John", "lastNames": ["Doe"], ... }
 *   }
 *
 * Response:
 *   {
 *     "instanceId": "PiIuACmx8Q8R7qPnAkLAqBAT",
 *     "journeyUrl": "https://...",
 *     "connectToken": "s4FUx8Ny...",
 *     "expiresIn": 120
 *   }
 */
app.post("/api/journey/start", async (req, res) => {
  try {
    if (!customerAccessToken) {
      return res.status(503).json({
        error: "Server not authenticated. Check your .env credentials.",
      });
    }

    const go = new Go({
      customerAccess: customerAccessToken,
      serverIdx: SERVER_IDX,
    });

    // Step 1: Start the journey
    const journey = await go.journeys.start({
      resourceId: req.body.resourceId ?? "a4c68509c24789888eb466@latest",
      context: {
        subject: {
          identity: req.body.identity ?? {},
        },
      },
    });

    // Step 2: Get a connect token for the mobile device
    const device = await go.devices.add({
      instanceId: journey.instanceId,
      scope: ["mobile"],
    });

    res.json({
      instanceId: journey.instanceId,
      journeyUrl: journey.instanceUrl,
      connectToken: device.connectToken,
      expiresIn: device.expiresIn,
    });
  } catch (err) {
    console.error("Journey start failed:", err.message);
    res.status(500).json({
      error: "Failed to start journey",
      message: err.message,
    });
  }
});

// ---------------------------------------------------------------------------
// Startup
// ---------------------------------------------------------------------------

async function start() {
  try {
    await authenticate();
  } catch (err) {
    console.error("Authentication failed:", err.message);
    console.error(
      "The server will start, but /api/journey/start will return 503."
    );
    console.error("Check your .env credentials and try restarting.");
  }

  app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
    console.log(`  GET  /                    — status`);
    console.log(`  GET  /health              — health check`);
    console.log(`  POST /api/journey/start   — create journey session`);
  });
}

start();
