const admin = require('firebase-admin');

// Ensure you have FIREBASE_SERVICE_ACCOUNT_KEY in .env or a valid path
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully');
  } else {
    console.warn('Firebase Admin NOT initialized: Missing FIREBASE_SERVICE_ACCOUNT_KEY');
  }
} catch (error) {
  console.error('Firebase Admin initialization error:', error);
}

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken || !admin.apps.length) return;

  const message = {
    notification: { title, body },
    data,
    token: fcmToken
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent push notification:', response);
  } catch (error) {
    console.error('Error sending push notification:', error);
  }
};

module.exports = { admin, sendPushNotification };
