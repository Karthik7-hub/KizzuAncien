const express = require('express');
const { createChallenge, getChallenges, submitProof, reviewSubmission, getSubmissionByChallenge, getSharedChallenges } = require('../controllers/challengeController');
const { getMessagesByChallenge, createMessage } = require('../controllers/messageController');
const { protect } = require('../middleware/authMiddleware');
const { apiLimiter } = require('../middleware/rateLimiter');
const upload = require('../utils/upload');
const router = express.Router();

router.post('/', protect, apiLimiter, createChallenge);
router.get('/', protect, getChallenges);
router.get('/shared/:friendId', protect, getSharedChallenges);
router.get('/:challengeId/submission', protect, getSubmissionByChallenge);
router.post('/submit', protect, apiLimiter, upload.single('file'), submitProof);
router.post('/review', protect, reviewSubmission);

// Discussion routes
router.get('/:challengeId/messages', protect, getMessagesByChallenge);
router.post('/:challengeId/messages', protect, apiLimiter, createMessage);

module.exports = router;
