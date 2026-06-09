const express = require('express');
const { sendRequest, respondToRequest, getFriends, removeFriend, cancelRequest } = require('../controllers/friendController');
const { protect } = require('../middleware/authMiddleware');
const { apiLimiter } = require('../middleware/rateLimiter');
const router = express.Router();

router.post('/request', protect, apiLimiter, sendRequest);
router.post('/respond', protect, apiLimiter, respondToRequest);
router.get('/', protect, getFriends);
router.delete('/:friendId', protect, removeFriend);
router.delete('/request/:requestId', protect, cancelRequest);

module.exports = router;
