const User = require('../models/User');
const Challenge = require('../models/Challenge');
const Friend = require('../models/Friend');
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
 * Sends reminders to users in shared streaks that are at risk of breaking.
 */
exports.sendStreakReminders = async (req, res, next) => {
  try {
    const todayStart = new Date().setHours(0,0,0,0);

    // Find friendships with active streaks not updated today
    const friendshipsAtRisk = await Friend.find({
      status: 'accepted',
      streak: { $gt: 0 },
      $or: [
        { lastStreakUpdate: { $lt: todayStart } },
        { lastStreakUpdate: { $exists: false } }
      ]
    }).populate('requester recipient');

    let sentCount = 0;
    for (const rel of friendshipsAtRisk) {
      if (rel.requester.fcmToken) {
        await sendPushNotification(
          rel.requester.fcmToken,
          "Streak at Risk",
          `Your shared streak with ${rel.recipient.name} ends soon!`,
          { type: 'streak_reminder' }
        );
        sentCount++;
      }
      if (rel.recipient.fcmToken) {
        await sendPushNotification(
          rel.recipient.fcmToken,
          "Streak at Risk",
          `Your shared streak with ${rel.requester.name} ends soon!`,
          { type: 'streak_reminder' }
        );
        sentCount++;
      }
    }

    res.json({ message: 'Streak reminders processed', sent: sentCount });
  } catch (error) {
    next(error);
  }
};

/**
 * Background task to reset broken relationship streaks.
 */
exports.resetBrokenStreaks = async (req, res, next) => {
  try {
    const todayStart = new Date().setHours(0,0,0,0);
    const yesterdayStart = todayStart - 86400000;

    // A streak is broken if the last completion was before yesterday.
    // Meaning no completion happened "yesterday" to maintain the streak.
    const brokenFriendships = await Friend.find({
      status: 'accepted',
      streak: { $gt: 0 },
      lastStreakUpdate: { $lt: new Date(yesterdayStart) }
    });

    const affectedUserIds = new Set();
    brokenFriendships.forEach(f => {
      affectedUserIds.add(f.requester.toString());
      affectedUserIds.add(f.recipient.toString());
    });

    const result = await Friend.updateMany(
      {
        status: 'accepted',
        streak: { $gt: 0 },
        lastStreakUpdate: { $lt: new Date(yesterdayStart) }
      },
      { $set: { streak: 0 } }
    );

    // Recalculate currentStreak for all affected users
    for (const userId of affectedUserIds) {
      const allFriendships = await Friend.find({
        status: 'accepted',
        $or: [{ requester: userId }, { recipient: userId }]
      });
      const bestStreak = Math.max(...allFriendships.map(f => f.streak), 0);
      await User.findByIdAndUpdate(userId, { $set: { currentStreak: bestStreak } });
    }

    res.json({ message: 'Broken streaks reset', modified: result.modifiedCount });
  } catch (error) {
    next(error);
  }
};
