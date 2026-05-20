const jwt = require('jsonwebtoken');

// ============================================================
// JWT SECRET
// VULN #7 — Weak JWT secret, trivially brute-forceable
// ============================================================
const JWT_SECRET = 'fluffy123';

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1]; // "Bearer <token>"

  try {
    // ============================================================
    // VULN #7 — Algorithm confusion (alg: none)
    // We manually decode the header to check the algorithm.
    // If alg is 'none' — we skip signature verification entirely
    // and trust the payload blindly.
    // ============================================================
    const parts = token.split('.');
    if (parts.length < 2) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    const headerJson = Buffer.from(parts[0], 'base64').toString('utf8');
    const header = JSON.parse(headerJson);

    if (header.alg === 'none') {
      // VULN: skip signature check entirely — trust payload blindly
      const payloadJson = Buffer.from(parts[1], 'base64').toString('utf8');
      const decoded = JSON.parse(payloadJson);
      req.user = decoded;
      return next();
    }

    // Normal HS256 verification
    const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
    req.user = decoded;
    next();

  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

module.exports = { authMiddleware, JWT_SECRET };
