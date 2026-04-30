const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const User   = require('../models/user.model');
const { JWT_SECRET } = require('../middleware/auth.middleware');

// ============================================================
// REGISTER
// VULN #4 — Mass Assignment
// We spread the entire req.body into the User constructor.
// Attacker can add "role": "admin" to the request body
// and it will be saved directly to the database.
// ============================================================
exports.register = async (req, res) => {
  try {
    const { password } = req.body;

    const password_hash = await bcrypt.hash(password, 10);

    // VULN #4: should be { username, email, password_hash }
    // Instead we spread all of req.body — attacker controls 'role'
    const user = new User({
      ...req.body,
      password_hash
    });

    await user.save();

    res.status(201).json({
      message:  'Welcome to Fluffy Paws!',
      user_id:  user._id,
      username: user.username,
      role:     user.role   // returned so attacker can confirm mass assignment worked
    });

  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// ============================================================
// LOGIN
// VULN #10 — No rate limiting at all (X-Forwarded-For bypass ready)
// VULN #12 — NoSQL Injection
// ============================================================
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // VULN #12 — username goes directly into query, no type check
    const user = await User.findOne({ username: username });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const passwordValid = await bcrypt.compare(password, user.password_hash);

    if (!passwordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // VULN #7 — Weak secret 'fluffy123'
    const token = jwt.sign(
      { id: user._id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({ token, role: user.role });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ============================================================
// GET USER PROFILE
// VULN #1 — BOLA/IDOR via path parameter
// VULN #9 — Excessive Data Exposure
// ============================================================
exports.getUser = async (req, res) => {
  try {
    const { id } = req.params;

    // VULN #1: should check req.user.id === id
    // VULN #9: should add .select('-password_hash -__v')
    const user = await User.findById(id);

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
