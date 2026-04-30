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

// ── Health check — самый простой маршрут, без файлов ─────────
// GET /api/ping → { status: 'ok' }
// Используется чтобы проверить что сервер живой
app.get('/api/ping', (req, res) => {
  res.json({ status: 'ok', service: 'Fluffy Paws API' });
});

// ── Start ─────────────────────────────────────────────────────
app.listen(3000, '127.0.0.1', () => {
  console.log('[SERVER] Fluffy Paws API running on http://127.0.0.1:3000');
  console.log('[SERVER] Environment: local lab only — not exposed externally');
});
