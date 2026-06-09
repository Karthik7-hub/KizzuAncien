const Notification = require('../models/Notification');

/**
 * Creates a notification and ensures the user only has the latest 50.
 */
exports.createCappedNotification = async (data) => {
  try {
    const notification = await Notification.create(data);

    // Count notifications for this recipient
    const count = await Notification.countDocuments({ recipient: data.recipient });

    if (count > 50) {
      // Find the oldest notification to delete
      const oldest = await Notification.findOne({ recipient: data.recipient })
        .sort('createdAt');

      if (oldest) {
        await Notification.findByIdAndDelete(oldest._id);
      }
    }

    return notification;
  } catch (error) {
    console.error('Error creating capped notification:', error);
    return null;
  }
};
