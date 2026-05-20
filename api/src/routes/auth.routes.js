const express = require('express');
const router  = express.Router();

const { register, login, getUser } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// Public routes
router.post('/auth/register', register);
router.post('/auth/login',    login);

// Protected routes
router.get('/users/:id', authMiddleware, getUser);

module.exports = router;
