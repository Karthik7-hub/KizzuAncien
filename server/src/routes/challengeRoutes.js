const express = require('express');
const { createChallenge, getChallenges, submitProof, reviewSubmission, getSubmissionByChallenge } = require('../controllers/challengeController');
const { protect } = require('../middleware/authMiddleware');
const { apiLimiter } = require('../middleware/rateLimiter');
const upload = require('../utils/upload');
const router = express.Router();

router.post('/', protect, apiLimiter, createChallenge);
router.get('/', protect, getChallenges);
router.get('/:challengeId/submission', protect, getSubmissionByChallenge);
router.post('/submit', protect, apiLimiter, upload.single('file'), submitProof);
router.post('/review', protect, reviewSubmission);

module.exports = router;
