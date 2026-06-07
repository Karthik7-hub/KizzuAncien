const express = require('express');
const { sendTruth, sendDare, getTruthsAndDares } = require('../controllers/truthDareController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/truth', protect, sendTruth);
router.post('/dare', protect, sendDare);
router.get('/history', protect, getTruthsAndDares);

module.exports = router;
