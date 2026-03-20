/**
 * GBG Go Reference — Companion Server
 *
 * A minimal Express server that demonstrates how to create journey sessions
 * using the GBG Go Core SDK (@gbg/go-core). The iOS reference app calls this
 * server to obtain a journey URL, which it then loads in a BridgeWebView.
 *
 * Flow:
 *   1. On startup the server authenticates with GBG Go using your credentials.
 *   2. POST /api/journey/start creates a new journey, registers a mobile
 *      device, connects it, and returns the journey URL plus tokens.
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

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const PORT = process.env.PORT || 3000;
const SERVER_IDX = parseInt(process.env.GO_SERVER_IDX || "0", 10);
const REGIONS = ["EU", "US", "AU"];
const SERVER_URL = process.env.GO_SERVER_URL || undefined;

const app = express();
app.use(express.json());

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
 *     "resourceId": "a4c68509c24789888eb466@latest"
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

    const serverOpts = SERVER_URL ? { serverURL: SERVER_URL } : {};
    const client = new Go({ customerAccess: customerAccessToken });

    // Step 1: Start a journey session
    const journey = await client.journeys.start(
      {
        resourceId: req.body.resourceId ?? process.env.GO_RESOURCE_ID,
        context: {
          subject: {},
          config: { delivery: "page" },
        },
      },
      serverOpts
    );

    // Step 2: Register a mobile device against the journey
    const device = await client.devices.add(
      {
        instanceId: journey.instanceId,
        scope: ["mobile"],
      },
      serverOpts
    );

    // Step 3: Connect the device to obtain an end-user token
    const connection = await client.devices.connect(
      { deviceConnect: device.connectToken },
      {
        deviceInfo: {
          deviceName: "iOS Reference App",
          deviceId: "ios-reference-device",
          deviceType: "mobile",
        },
        connectToken: device.connectToken,
      },
      serverOpts
    );

    // Step 4: Fetch the interaction to validate the session
    const unauthenticatedClient = new Go();
    await unauthenticatedClient.interactions.fetch(
      { interactionAccess: String(connection.endUserToken) },
      { instanceId: journey.instanceId },
      serverOpts
    );

    // Return the journey details to the iOS app
    const result = {
      instanceId: journey.instanceId,
      journeyUrl: journey.instanceUrl,
      connectToken: device.connectToken,
      expiresIn: device.expiresIn,
    };
    console.log("Journey started:", result.instanceId);
    res.json(result);
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
