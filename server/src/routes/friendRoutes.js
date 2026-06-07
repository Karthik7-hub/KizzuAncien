const express = require('express');
const { sendRequest, respondToRequest, getFriends, removeFriend, cancelRequest } = require('../controllers/friendController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/request', protect, sendRequest);
router.post('/respond', protect, respondToRequest);
router.get('/', protect, getFriends);
router.delete('/:friendId', protect, removeFriend);
router.delete('/request/:requestId', protect, cancelRequest);

module.exports = router;
