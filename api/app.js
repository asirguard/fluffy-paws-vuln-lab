const express  = require('express');
const mongoose = require('mongoose');

const app = express();

// ── Middleware ────────────────────────────────────────────────
app.use(express.json());

// ── CORS ─────────────────────────────────────────────────────
// VULN: wildcard origin — accepts requests from any domain
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ── Database ──────────────────────────────────────────────────
mongoose.connect('mongodb://127.0.0.1:27017/fluffy-paws')
  .then(() => console.log('[DB] MongoDB connected → fluffy-paws'))
  .catch(err => console.error('[DB] Connection error:', err));

// ── Routes ────────────────────────────────────────────────────
const authRoutes = require('./src/routes/auth.routes');

app.use('/api', authRoutes);

// ── Health check ──────────────────────────────────────────────
// GET /api/ping → { status: 'ok' }
app.get('/api/ping', (req, res) => {
  res.json({ status: 'ok', service: 'Fluffy Paws API' });
});

// ── Start ─────────────────────────────────────────────────────
// Bind to 0.0.0.0 so the API is reachable from the Windows host
// and Kali over the VirtualBox Host-Only network
app.listen(3000, '0.0.0.0', () => {
  console.log('[SERVER] Fluffy Paws API running on http://0.0.0.0:3000');
  console.log('[SERVER] Accessible from host and Kali over Host-Only network');
});
