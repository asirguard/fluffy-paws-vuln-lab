const mongoose = require('mongoose');

// ============================================================
// USER MODEL
// Vulnerabilities embedded here:
//   #4  Mass Assignment  — no field restrictions on schema level
//   #9  Excessive Data Exposure — password_hash stored, returned raw
//   #12 NoSQL Injection — plaintext password stored, compared in-query in login()
// ============================================================

const userSchema = new mongoose.Schema({
  username:      { type: String, required: true, unique: true },
  email:         { type: String, required: true, unique: true },
  password_hash: { type: String, required: true },

  // VULN #12 - NoSQL Injection
  // Plaintext password is stored and compared directly inside the login query
  // (User.findOne({ username, password })). This lets an attacker bypass auth
  // with operator injection such as {"$ne": null}. password_hash is kept as well
  // so Excessive Data Exposure (#9) still leaks a hash.
  password:      { type: String },

  // VULN #4 — Mass Assignment
  // 'role' should never be set by the client.
  role:          { type: String, default: 'user' },

  created_at:    { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
