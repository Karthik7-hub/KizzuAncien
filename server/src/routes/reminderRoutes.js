const express = require('express');
const { sendDailyChallengeReminders, sendStreakReminders, resetBrokenStreaks, checkExpiredChallenges } = require('../controllers/reminderController');
const router = express.Router();

// Middleware to check for a CRON secret to prevent public abuse
const cronAuth = (req, res, next) => {
  const secret = req.headers['x-cron-secret'];
  if (process.env.CRON_SECRET && secret !== process.env.CRON_SECRET) {
    return res.status(401).json({ message: 'Unauthorized CRON access' });
  }
  next();
};

router.post('/daily-challenges', cronAuth, sendDailyChallengeReminders);
router.post('/streaks', cronAuth, sendStreakReminders);
router.post('/reset-streaks', cronAuth, resetBrokenStreaks);
router.post('/check-expiry', cronAuth, checkExpiredChallenges);

module.exports = router;
