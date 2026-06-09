const User = require('../models/User');
const Challenge = require('../models/Challenge');
const { sendPushNotification } = require('../services/firebaseService');

/**
 * Sends daily reminders to users with pending challenges.
 * Intended to be triggered by a CRON job.
 */
exports.sendDailyChallengeReminders = async (req, res, next) => {
  try {
    // 1. Find all active challenges due soon
    const today = new Date();
    const activeChallenges = await Challenge.find({
      status: 'pending',
      deadline: { $gt: today }
    }).populate('recipient');

    let sentCount = 0;
    for (const challenge of activeChallenges) {
      if (challenge.recipient && challenge.recipient.fcmToken) {
        await sendPushNotification(
          challenge.recipient.fcmToken,
          "Reminder",
          `${challenge.title}\nStay consistent`,
          { type: 'challenge_reminder', id: challenge._id.toString() }
        );
        sentCount++;
      }
    }

    res.json({ message: 'Reminders processed', sent: sentCount });
  } catch (error) {
    next(error);
  }
};

/**
 * Sends reminders to users at risk of losing their streak.
 */
exports.sendStreakReminders = async (req, res, next) => {
  try {
    // Logic: Find users who haven't completed a challenge today
    const todayStart = new Date().setHours(0,0,0,0);
    const usersAtRisk = await User.find({
      fcmToken: { $ne: null },
      streak: { $gt: 0 },
      $or: [
        { lastCompletedDate: { $lt: todayStart } },
        { lastCompletedDate: { $exists: false } }
      ]
    });

    let sentCount = 0;
    for (const user of usersAtRisk) {
      await sendPushNotification(
        user.fcmToken,
        "Streak",
        "Maintain your consistency\nTap to complete task",
        { type: 'streak_reminder' }
      );
      sentCount++;
    }

    res.json({ message: 'Streak reminders processed', sent: sentCount });
  } catch (error) {
    next(error);
  }
};
