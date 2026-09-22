# THISULINK — Backend Infrastructure

> **Domain**: `thisulink.xyz` · **Host**: Linux laptop (always-on) · **Stack**: Cloudflare + Tailscale + PocketBase + Node.js/Express

This document covers the complete self-hosted backend that powers the THISULINK multimodal diabetic screening platform — from DNS and tunnel security to the database, authentication, and triage API.

---

## Architecture overview

```
Internet (Patient / ASHA / Mentor device)
        │
        │  HTTPS (443)
        ▼
┌───────────────────────┐
│    Cloudflare         │  DNS • CDN • DDoS protection • SSL termination
│    thisulink.xyz      │  Cloudflare Tunnel (cloudflared) — no open ports
└────────────┬──────────┘
             │  Encrypted Cloudflare Tunnel
             ▼
┌────────────────────────────────────────────┐
│  Linux Laptop  (always-on, home network)   │
│                                            │
│  ┌──────────────┐   ┌────────────────────┐ │
│  │  cloudflared │   │  Tailscale         │ │
│  │  (tunnel     │   │  (admin / SSH VPN) │ │
│  │   daemon)    │   │  100.x.x.x mesh    │ │
│  └──────┬───────┘   └────────────────────┘ │
│         │ localhost:8090                    │
│  ┌──────▼───────┐                          │
│  │  PocketBase  │  Auth • DB • Files       │
│  │  :8090       │  Realtime • Hooks        │
│  └──────┬───────┘                          │
│         │ localhost:3000                   │
│  ┌──────▼───────┐                          │
│  │  Node.js /   │  Retinal grading API     │
│  │  Express     │  Triage engine           │
│  │  :3000       │  ONNX inference          │
│  └──────────────┘                          │
└────────────────────────────────────────────┘
```

---

## Contents

1. [Cloudflare setup](#1-cloudflare-setup)
2. [Tailscale VPN](#2-tailscale-vpn)
3. [PocketBase](#3-pocketbase)
4. [Node.js / Express API](#4-nodejs--express-api)
5. [Process management (PM2)](#5-process-management-pm2)
6. [Environment variables](#6-environment-variables)
7. [Deployment checklist](#7-deployment-checklist)
8. [Backup and recovery](#8-backup-and-recovery)

---

## 1. Cloudflare setup

### Why Cloudflare Tunnel (not open ports)
The Linux laptop has a dynamic home IP and sits behind a NAT router. Cloudflare Tunnel (`cloudflared`) creates an outbound-only encrypted connection from the laptop to Cloudflare's edge — **no port forwarding, no static IP, no exposed ports on the home router**.

### DNS records (thisulink.xyz)

| Type | Name | Value | Proxied |
|---|---|---|---|
| CNAME | `@` (thisulink.xyz) | `<tunnel-id>.cfargotunnel.com` | ✅ Yes |
| CNAME | `www` | `thisulink.xyz` | ✅ Yes |
| CNAME | `pb` (pb.thisulink.xyz) | `<tunnel-id>.cfargotunnel.com` | ✅ Yes |
| CNAME | `api` (api.thisulink.xyz) | `<tunnel-id>.cfargotunnel.com` | ✅ Yes |

### Install cloudflared on the Linux laptop

```bash
# Download and install
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Authenticate (opens browser — log in with thisulink Cloudflare account)
cloudflared tunnel login

# Create the tunnel
cloudflared tunnel create thisulink-prod
# Note the tunnel ID printed here — use it in DNS records above
```

### Tunnel config file: `/etc/cloudflared/config.yml`

```yaml
tunnel: thisulink-prod
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  # PocketBase — main app + Flutter SDK calls
  - hostname: thisulink.xyz
    service: http://localhost:8090

  - hostname: pb.thisulink.xyz
    service: http://localhost:8090

  # Node.js / Express — retinal grading + triage API
  - hostname: api.thisulink.xyz
    service: http://localhost:3000

  # Catch-all
  - service: http_status:404
```

### Run cloudflared as a systemd service

```bash
cloudflared service install
systemctl enable cloudflared
systemctl start cloudflared
systemctl status cloudflared
```

### Cloudflare security settings (dashboard)

| Setting | Value |
|---|---|
| SSL/TLS mode | Full (strict) |
| Always use HTTPS | On |
| HSTS | Enabled, max-age 1 year |
| Bot fight mode | On |
| Rate limiting rule | 100 req/min per IP on `/api/` |
| WAF — OWASP ruleset | Managed rules enabled |

---

## 2. Tailscale VPN

Tailscale provides a private WireGuard mesh between your laptop, phones, and any other admin device. Use it for:
- SSH into the laptop from anywhere without exposing port 22
- Accessing PocketBase admin UI (`100.x.x.x:8090/_`) from your phone/laptop without exposing it publicly
- Zero-trust access: only Tailscale-authenticated devices can reach the admin panel

### Install on the Linux laptop

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh
```

### Install on your admin devices (phone / Windows laptop)
Download Tailscale from the official site or Play Store. Log in with the same account. All devices appear as `100.x.x.x` addresses in a private mesh.

### Key Tailscale rules

- **ACL**: Only allow the laptop's Tailscale IP to access PocketBase port 8090 from outside.
- **SSH**: `tailscale ssh <linux-laptop-hostname>` replaces password SSH from any Tailscale device.
- **PocketBase admin**: Browse to `http://100.x.x.x:8090/_` from any Tailscale device for admin access (never expose `/_` through Cloudflare).

### Nginx on localhost (optional, if both PocketBase and Express need routing)

```nginx
# /etc/nginx/sites-available/thisulink
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
    }
}
```

---

## 3. PocketBase

PocketBase is the primary backend — handles auth, database, file storage, realtime subscriptions, and server-side JavaScript hooks.

### Download and install

```bash
mkdir -p /opt/thisulink/pocketbase && cd /opt/thisulink/pocketbase

# Download latest PocketBase for Linux amd64
wget https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_linux_amd64.zip
unzip pocketbase_linux_amd64.zip
chmod +x pocketbase

# First run — creates pb_data/ directory
./pocketbase serve --http="127.0.0.1:8090"
```

Open `http://100.x.x.x:8090/_` (via Tailscale) to set up the admin account on first launch.

### Collections (create in admin UI)

#### `asha_workers`
| Field | Type | Notes |
|---|---|---|
| name | text | required |
| email | email | unique, used for auth |
| phone | text | |
| district | text | |
| assigned_patients | relation (patients) | multiple |

#### `mentors`
| Field | Type | Notes |
|---|---|---|
| name | text | required |
| email | email | unique, used for auth |
| specialisation | text | e.g. Ophthalmology, Diabetology |
| hospital | text | |

#### `patients`
| Field | Type | Notes |
|---|---|---|
| name | text | required |
| age | number | |
| gender | select | Male / Female / Other |
| diabetes_type | select | Type 1 / Type 2 / GDM |
| asha_worker | relation (asha_workers) | single |
| current_cycle_day | number | 1–6 |
| triage_colour | select | Green / Yellow / Orange / Red |

#### `cycle_sessions`
| Field | Type | Notes |
|---|---|---|
| patient | relation (patients) | required |
| cycle_day | number | 1–6 |
| date | date | |
| swe_modulus_kpa | number | Young's modulus E |
| swe_cs_ms | number | Shear-wave speed c_s (m/s) |
| tissue_class | select | A / B / C |
| delta_t_celsius | number | Thermometry ΔT |
| glucose_mgdl | number | Blood glucose |
| retinal_image | file | JPEG/PNG, stored in PocketBase Files |
| dr_grade | number | 0–4, nullable |
| referable_prob | number | 0.0–1.0, nullable |
| triage_colour | select | Green / Yellow / Orange / Red |

#### `triage_results`
| Field | Type | Notes |
|---|---|---|
| patient | relation (patients) | |
| session | relation (cycle_sessions) | |
| triage_colour | select | Green / Yellow / Orange / Red |
| computed_at | date | |
| notes | text | optional clinician note |

#### `relay_alerts`
| Field | Type | Notes |
|---|---|---|
| asha_worker | relation (asha_workers) | |
| patient | relation (patients) | |
| message | text | |
| acknowledged | bool | default false |

### PocketBase JavaScript hook: triage engine

Create at `pb_hooks/triage.pb.js`:

```javascript
// Runs after every cycle_sessions record is created or updated
onRecordAfterCreateRequest((e) => {
  computeTriage(e.record);
}, "cycle_sessions");

onRecordAfterUpdateRequest((e) => {
  computeTriage(e.record);
}, "cycle_sessions");

function computeTriage(session) {
  const tissueClass   = session.get("tissue_class");       // "A", "B", "C"
  const deltaT        = session.get("delta_t_celsius") || 0;
  const drGrade       = session.get("dr_grade") ?? -1;
  const referableProb = session.get("referable_prob") || 0;
  const glucose       = session.get("glucose_mgdl") || 0;

  let colour = "Green";

  if (
    tissueClass === "C" ||
    (referableProb >= 0.50 && drGrade >= 3) ||
    glucose > 400
  ) {
    colour = "Red";
  } else if (
    (tissueClass === "B" && deltaT >= 2.2) ||
    referableProb >= 0.50 ||
    glucose > 300
  ) {
    colour = "Orange";
  } else if (
    tissueClass === "B" ||
    deltaT >= 2.2 ||
    drGrade >= 2 ||
    glucose > 180
  ) {
    colour = "Yellow";
  }

  // Write triage result
  const collection = $app.dao().findCollectionByNameOrId("triage_results");
  const record = new Record(collection);
  record.set("patient", session.get("patient"));
  record.set("session", session.id);
  record.set("triage_colour", colour);
  record.set("computed_at", new Date().toISOString());
  $app.dao().saveRecord(record);

  // Update patient's current triage colour
  const patient = $app.dao().findRecordById("patients", session.get("patient"));
  patient.set("triage_colour", colour);
  $app.dao().saveRecord(patient);

  // If Orange or Red → create relay alert for the ASHA worker
  if (colour === "Orange" || colour === "Red") {
    const patientName = patient.get("name");
    const cycleDay    = session.get("cycle_day");
    const ashaId      = patient.get("asha_worker");

    const alertCol = $app.dao().findCollectionByNameOrId("relay_alerts");
    const alert = new Record(alertCol);
    alert.set("asha_worker", ashaId);
    alert.set("patient", patient.id);
    alert.set("message",
      `⚠️ ${patientName} — Triage ${colour} on Day ${cycleDay}. Immediate review needed.`
    );
    alert.set("acknowledged", false);
    $app.dao().saveRecord(alert);
  }
}
```

### Run PocketBase with PM2 (see Section 5)

---

## 4. Node.js / Express API

The Express server handles:
- **Retinal grading** (`POST /api/retinal/grade`) — runs ONNX INT8 inference server-side when Flutter app is online
- **Batch triage** (`POST /api/triage/batch`) — recompute triage for multiple sessions
- **Healthcheck** (`GET /api/health`)
- **Webhook receiver** from PocketBase hooks (optional)

### Setup

```bash
mkdir -p /opt/thisulink/api && cd /opt/thisulink/api
npm init -y
npm install express cors helmet morgan dotenv onnxruntime-node multer sharp axios
```

### `src/index.js`

```javascript
require('dotenv').config();
const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');

const retinalRouter = require('./routes/retinal');
const triageRouter  = require('./routes/triage');

const app = express();

app.use(helmet());
app.use(cors({ origin: ['https://thisulink.xyz', 'http://localhost'] }));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));

app.use('/api/retinal', retinalRouter);
app.use('/api/triage',  triageRouter);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '127.0.0.1', () => {
  console.log(`THISULINK API running on 127.0.0.1:${PORT}`);
});
```

### `src/routes/retinal.js` — ONNX grading

```javascript
const express = require('express');
const multer  = require('multer');
const sharp   = require('sharp');
const ort     = require('onnxruntime-node');
const path    = require('path');

const router  = express.Router();
const upload  = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

const IMAGENET_MEAN = [0.485, 0.456, 0.406];
const IMAGENET_STD  = [0.229, 0.224, 0.225];
const MODEL_PATH    = path.join(__dirname, '../../models/thisulink_retinal_efficientnet_b0_int8.onnx');

let session;
(async () => { session = await ort.InferenceSession.create(MODEL_PATH); })();

async function preprocessImage(buffer) {
  // Resize to 224x224, normalize to ImageNet stats
  const { data, info } = await sharp(buffer)
    .resize(224, 224)
    .raw()
    .toBuffer({ resolveWithObject: true });

  const float32 = new Float32Array(3 * 224 * 224);
  for (let i = 0; i < 224 * 224; i++) {
    float32[i]                 = (data[i * 3]     / 255 - IMAGENET_MEAN[0]) / IMAGENET_STD[0];
    float32[i + 224 * 224]     = (data[i * 3 + 1] / 255 - IMAGENET_MEAN[1]) / IMAGENET_STD[1];
    float32[i + 2 * 224 * 224] = (data[i * 3 + 2] / 255 - IMAGENET_MEAN[2]) / IMAGENET_STD[2];
  }
  return new ort.Tensor('float32', float32, [1, 3, 224, 224]);
}

// POST /api/retinal/grade
// Content-Type: multipart/form-data   field: image (JPEG/PNG)
router.post('/grade', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image uploaded' });

    const inputTensor = await preprocessImage(req.file.buffer);
    const feeds = { input: inputTensor };
    const results = await session.run(feeds);

    const gradeProbs   = Array.from(results['grade_probs'].data);
    const referableRaw = results['referable_prob'].data[0];

    const predictedGrade = gradeProbs.indexOf(Math.max(...gradeProbs));
    const gradeNames = ['No DR', 'Mild', 'Moderate', 'Severe', 'Proliferative'];

    res.json({
      thisulink_module: 'retinal',
      research_output: {
        predicted_dr_grade:      predictedGrade,
        grade_name:              gradeNames[predictedGrade],
        grade_probabilities: {
          '0': +gradeProbs[0].toFixed(4),
          '1': +gradeProbs[1].toFixed(4),
          '2': +gradeProbs[2].toFixed(4),
          '3': +gradeProbs[3].toFixed(4),
          '4': +gradeProbs[4].toFixed(4),
        },
        referable_dr_probability: +referableRaw.toFixed(4),
        referable:               referableRaw >= 0.50,
        triage_contribution:     referableRaw >= 0.50 && predictedGrade >= 3
                                   ? 'RED' : referableRaw >= 0.50
                                   ? 'ORANGE' : predictedGrade >= 2
                                   ? 'YELLOW' : 'GREEN',
      },
      disclaimer: 'Research output only — not a diagnosis. Clinician review required.',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Inference failed', detail: err.message });
  }
});

module.exports = router;
```

### `src/routes/triage.js` — manual triage recompute

```javascript
const express = require('express');
const router  = express.Router();

function computeTriageColour({ tissueClass, deltaT, drGrade, referableProb, glucose }) {
  if (
    tissueClass === 'C' ||
    (referableProb >= 0.50 && drGrade >= 3) ||
    glucose > 400
  ) return 'Red';

  if (
    (tissueClass === 'B' && deltaT >= 2.2) ||
    referableProb >= 0.50 ||
    glucose > 300
  ) return 'Orange';

  if (
    tissueClass === 'B' ||
    deltaT >= 2.2 ||
    drGrade >= 2 ||
    glucose > 180
  ) return 'Yellow';

  return 'Green';
}

// POST /api/triage/compute
// Body: { tissueClass, deltaT, drGrade, referableProb, glucose }
router.post('/compute', (req, res) => {
  const { tissueClass, deltaT, drGrade, referableProb, glucose } = req.body;
  const colour = computeTriageColour({ tissueClass, deltaT, drGrade, referableProb, glucose });
  res.json({ triage_colour: colour, computed_at: new Date().toISOString() });
});

module.exports = router;
```

### `package.json` scripts

```json
{
  "scripts": {
    "start":  "node src/index.js",
    "dev":    "nodemon src/index.js",
    "test":   "jest"
  }
}
```

---

## 5. Process management (PM2)

PM2 keeps both PocketBase and the Express API alive across reboots.

```bash
npm install -g pm2

# Start PocketBase
pm2 start /opt/thisulink/pocketbase/pocketbase \
  --name pocketbase \
  -- serve --http="127.0.0.1:8090" --dir="/opt/thisulink/pocketbase/pb_data"

# Start Express API
pm2 start /opt/thisulink/api/src/index.js \
  --name thisulink-api \
  --env production

# Save and enable on boot
pm2 save
pm2 startup systemd
# Run the printed command as root
```

### Useful PM2 commands

```bash
pm2 list                    # show running processes
pm2 logs pocketbase         # PocketBase logs
pm2 logs thisulink-api      # Express logs
pm2 restart thisulink-api   # restart Express after code change
pm2 monit                   # live CPU/RAM dashboard
```

---

## 6. Environment variables

### `/opt/thisulink/api/.env`

```env
PORT=3000
NODE_ENV=production

# PocketBase admin credentials (for server-to-server calls)
PB_URL=http://127.0.0.1:8090
PB_ADMIN_EMAIL=admin@thisulink.xyz
PB_ADMIN_PASSWORD=<strong-password>

# ONNX model path
ONNX_MODEL_PATH=/opt/thisulink/api/models/thisulink_retinal_efficientnet_b0_int8.onnx

# Cloudflare (for cache purge or D1 if added later)
CF_ZONE_ID=<cloudflare-zone-id>
CF_API_TOKEN=<cloudflare-api-token>

# Tailscale (informational)
TAILSCALE_IP=100.x.x.x
```

> [!CAUTION]
> Never commit `.env` to Git. It is in `.gitignore` by default. Use `cp .env.example .env` on each new deployment.

### `.env.example` (safe to commit)

```env
PORT=3000
NODE_ENV=production
PB_URL=http://127.0.0.1:8090
PB_ADMIN_EMAIL=
PB_ADMIN_PASSWORD=
ONNX_MODEL_PATH=
CF_ZONE_ID=
CF_API_TOKEN=
TAILSCALE_IP=
```

---

## 7. Deployment checklist

### First-time setup on the Linux laptop

```bash
# 1. Install dependencies
sudo apt update && sudo apt install -y nginx unzip curl git nodejs npm

# 2. Clone repo
git clone https://github.com/thisulink/thisulink.git /opt/thisulink/repo

# 3. Install and start cloudflared (Section 1)

# 4. Install and start Tailscale (Section 2)
curl -fsSL https://tailscale.com/install.sh | sh && tailscale up --ssh

# 5. Set up PocketBase (Section 3)
mkdir -p /opt/thisulink/pocketbase
# download + unzip pocketbase binary here

# 6. Set up Express API (Section 4)
cd /opt/thisulink/api && npm install

# 7. Copy ONNX model
cp /path/to/thisulink_retinal_efficientnet_b0_int8.onnx /opt/thisulink/api/models/

# 8. Copy .env
cp .env.example .env && nano .env   # fill in secrets

# 9. Start with PM2 (Section 5)

# 10. Verify
curl https://api.thisulink.xyz/api/health
curl https://thisulink.xyz/_/api/health   # PocketBase health
```

### After every code update

```bash
cd /opt/thisulink/repo && git pull origin main
cd /opt/thisulink/api  && npm install
pm2 restart thisulink-api
```

---

## 8. Backup and recovery

### PocketBase data backup (cron)

```bash
# /etc/cron.d/thisulink-backup
0 2 * * * root tar -czf /opt/backups/pb_data_$(date +\%Y\%m\%d).tar.gz \
  /opt/thisulink/pocketbase/pb_data && \
  find /opt/backups -name "pb_data_*.tar.gz" -mtime +7 -delete
```

### Restore

```bash
pm2 stop pocketbase
tar -xzf /opt/backups/pb_data_YYYYMMDD.tar.gz -C /
pm2 start pocketbase
```

### Cloudflare Tunnel credential backup

```bash
cp /root/.cloudflared/<tunnel-id>.json /opt/backups/cloudflare_tunnel_creds.json
```

---

## 9. Repository structure (`backend/` folder in thisulink/thisulink)

```
backend/
├── .env.example
├── package.json
├── src/
│   ├── index.js               Express entry point
│   └── routes/
│       ├── retinal.js         ONNX retinal grading
│       └── triage.js          Triage recompute
├── models/
│   └── .gitkeep              (ONNX model not committed — download separately)
├── pb_hooks/
│   └── triage.pb.js           PocketBase JS hook (triage engine)
├── nginx/
│   └── thisulink.conf         Nginx local reverse proxy config
├── cloudflared/
│   └── config.yml             Cloudflare Tunnel config template
└── README.md                  ← this file
```

---

## Ports at a glance

| Service | Binds to | Exposed publicly via |
|---|---|---|
| PocketBase | `127.0.0.1:8090` | Cloudflare Tunnel → `thisulink.xyz` |
| PocketBase admin `/_` | `127.0.0.1:8090` | **Tailscale only** — never via Cloudflare |
| Express API | `127.0.0.1:3000` | Cloudflare Tunnel → `api.thisulink.xyz` |
| cloudflared | outbound only | Cloudflare edge |
| Tailscale | `100.x.x.x` | WireGuard mesh — admin SSH + DB access |
| SSH | `22` (Tailscale only) | No public exposure |
