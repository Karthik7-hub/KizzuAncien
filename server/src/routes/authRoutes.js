const express = require('express');
const { register, login, googleLogin, refreshToken, checkEmail } = require('../controllers/authController');
const { authLimiter } = require('../middleware/rateLimiter');
const router = express.Router();

router.post('/register', authLimiter, register);
router.post('/login', authLimiter, login);
router.post('/google', authLimiter, googleLogin);
router.post('/refresh-token', refreshToken);
router.get('/check-email/:email', checkEmail);

module.exports = router;
