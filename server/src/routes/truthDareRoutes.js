const express = require('express');
const { sendTruth, sendDare, getTruthsAndDares, answerTruth, completeDare } = require('../controllers/truthDareController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/truth', protect, sendTruth);
router.post('/dare', protect, sendDare);
router.post('/truth/answer', protect, answerTruth);
router.post('/dare/complete', protect, completeDare);
router.get('/history', protect, getTruthsAndDares);

module.exports = router;
