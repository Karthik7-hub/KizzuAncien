const admin = require('firebase-admin');

if (admin.apps.length === 0) {
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
    console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT not found in environment. Firebase features will be disabled.');
  }
}

module.exports = admin;
