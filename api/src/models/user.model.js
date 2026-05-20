const mongoose = require('mongoose');

// ============================================================
// USER MODEL
// Vulnerabilities embedded here:
//   #4  Mass Assignment  — no field restrictions on schema level
//   #9  Excessive Data Exposure — password_hash stored, returned raw
// ============================================================

const userSchema = new mongoose.Schema({
  username:      { type: String, required: true, unique: true },
  email:         { type: String, required: true, unique: true },
  password_hash: { type: String, required: true },

  // VULN #4 — Mass Assignment
  // 'role' should never be set by the client.
  role:          { type: String, default: 'user' },

  created_at:    { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
