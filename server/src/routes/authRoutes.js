const express = require('express');
const { register, login, googleLogin, refreshToken, checkEmail, logout } = require('../controllers/authController');
const { authLimiter } = require('../middleware/rateLimiter');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/google', authLimiter, googleLogin);
router.post('/refresh-token', refreshToken);
router.get('/check-email/:email', checkEmail);
router.post('/logout', protect, logout);

module.exports = router;
