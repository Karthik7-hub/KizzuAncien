const admin = require('firebase-admin');
const User = require('../models/User');

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin Initialized');
  } catch (error) {
    console.error('❌ Firebase Admin Initialization Error:', error.message);
  }
} else {
  console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT not found in environment variables');
}

/**
 * Sends a push notification to a specific user or token.
 * @param {string} target - FCM Token or User ID
 * @param {string} title - Notification Title
 * @param {string} body - Notification Body
 * @param {object} data - Extra data payload
 */
exports.sendPushNotification = async (target, title, body, data = {}) => {
  let token = target;

  // If target is a User ID (24 char hex), fetch the user's token
  if (target && target.length === 24) {
    const user = await User.findById(target);
    if (!user || !user.fcmToken) {
      console.log(`ℹ️ No FCM token found for user: ${target}. Skipping push.`);
      return;
    }
    token = user.fcmToken;
  }

  if (!token) {
    console.warn('⚠️ Aborting FCM send: No token provided');
    return;
  }

  console.log(`📡 Attempting to send Push Notification: "${title}" to token: ${token.substring(0, 10)}...`);

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
    console.log('✅ FCM Sent Successfully. MessageID:', response);
    return response;
  } catch (error) {
    console.error('❌ FCM Send Error:', error.message);

    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      console.warn('🚫 Token is invalid/expired. Removing from database...');
      await User.updateOne({ fcmToken: token }, { $set: { fcmToken: null } });
      return { error: 'token_expired' };
    }
    return { error: error.message };
  }
};
