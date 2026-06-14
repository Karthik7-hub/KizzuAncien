const express = require('express');
const { checkUsernameAvailability, getProfile, getUserProfile, updateProfile, searchUsers, updateFcmToken } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.get('/check-username', checkUsernameAvailability);

router.get('/profile', protect, getProfile);
router.get('/profile/:id', protect, getUserProfile);
router.put('/profile', protect, updateProfile);
router.put('/fcm-token', protect, updateFcmToken);
router.get('/search', protect, searchUsers);

module.exports = router;

