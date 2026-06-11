const admin = require('../config/firebase');
const User = require('../models/User');

/**
 * Sends a push notification to a specific user or token.
 * @param {string} target - FCM Token or User ID
 * @param {string} title - Notification Title
 * @param {string} body - Notification Body
 * @param {object} data - Extra data payload
 */
exports.sendPushNotification = async (target, title, body, data = {}) => {
  if (admin.apps.length === 0) {
    console.warn('Cannot send notification: Firebase Admin not initialized');
    return { error: 'firebase_not_initialized' };
  }

  let token = target;

  // If target is a User ID (24 char hex), fetch the user's token
  if (target && target.length === 24) {
    const user = await User.findById(target);
    if (!user || !user.fcmToken) {
      return;
    }
    token = user.fcmToken;
  }

  if (!token) {
    return;
  }

  const message = {
    notification: { title, body },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'kizzu_channel',
        priority: 'high',
        icon: 'ic_notification'
      },
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    return response;
  } catch (error) {
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      await User.updateOne({ fcmToken: token }, { $set: { fcmToken: null } });
      return { error: 'token_expired' };
    }
    return { error: error.message };
  }
};
