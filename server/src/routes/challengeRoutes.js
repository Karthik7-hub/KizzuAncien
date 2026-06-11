const express = require('express');
const {
  createChallenge,
  getChallenges,
  submitProof,
  editSubmission,
  reviewSubmission,
  getSubmissionByChallenge,
  getSharedChallenges,
  getChallengeActivities,
  uploadAttachment
} = require('../controllers/challengeController');
const { getMessagesByChallenge, createMessage } = require('../controllers/messageController');
const { protect } = require('../middleware/authMiddleware');
const { apiLimiter } = require('../middleware/rateLimiter');
const upload = require('../utils/upload');
const router = express.Router();

router.post('/', protect, apiLimiter, createChallenge);
router.get('/', protect, getChallenges);
router.get('/shared/:friendId', protect, getSharedChallenges);
router.get('/:challengeId/submission', protect, getSubmissionByChallenge);
router.get('/:challengeId/activities', protect, getChallengeActivities);
router.post('/submit', protect, apiLimiter, submitProof);
router.post('/edit', protect, apiLimiter, editSubmission);
router.post('/review', protect, reviewSubmission);
router.post('/upload', protect, upload.single('file'), uploadAttachment);

// Discussion routes
router.get('/:challengeId/messages', protect, getMessagesByChallenge);
router.post('/:challengeId/messages', protect, apiLimiter, createMessage);

module.exports = router;
