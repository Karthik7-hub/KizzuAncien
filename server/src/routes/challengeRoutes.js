const express = require('express');
const { createChallenge, getChallenges, submitProof, reviewSubmission, getSubmissionByChallenge, getSharedChallenges, createNote, getNotes, reorderNotes, updateNote, deleteNote } = require('../controllers/challengeController');
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

// Note routes
router.post('/:challengeId/notes', protect, apiLimiter, upload.array('files'), createNote);
router.get('/:challengeId/notes', protect, getNotes);
router.put('/:challengeId/notes/reorder', protect, reorderNotes);
router.put('/:challengeId/notes/:noteId', protect, apiLimiter, upload.array('files'), updateNote);
router.delete('/:challengeId/notes/:noteId', protect, deleteNote);

// Discussion routes
router.get('/:challengeId/messages', protect, getMessagesByChallenge);
router.post('/:challengeId/messages', protect, apiLimiter, createMessage);

module.exports = router;
