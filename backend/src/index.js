require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');

const retinalRouter = require('./routes/retinal');
const triageRouter  = require('./routes/triage');
const healthRouter  = require('./routes/health');

const app = express();

// ── Security middleware ──────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: [
    'https://thisulink.xyz',
    'https://api.thisulink.xyz',
    'https://pb.thisulink.xyz',
    'http://localhost:3000',
    'http://localhost:8090',
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-THISULINK-Key'],
}));

// ── Logging ──────────────────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── Body parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/health',   healthRouter);
app.use('/api/retinal',  retinalRouter);
app.use('/api/triage',   triageRouter);

// ── 404 catch-all ────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

// ── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

// ── Start server ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
const HOST = '127.0.0.1'; // only reachable via Cloudflare Tunnel or Tailscale

app.listen(PORT, HOST, () => {
  console.log(`✅  THISULINK API  →  http://${HOST}:${PORT}`);
  console.log(`    ENV: ${process.env.NODE_ENV}`);
  console.log(`    PocketBase: ${process.env.PB_URL}`);
});

module.exports = app; // for Jest supertest
