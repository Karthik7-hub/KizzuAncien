const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  type: {
    type: String,
    enum: ['challenge_received', 'submission_received', 'challenge_approved', 'challenge_rejected', 'friend_request', 'friend_request_accepted', 'truth_received', 'dare_received'],
    required: true
  },
  relatedId: { type: mongoose.Schema.Types.ObjectId }, // Challenge ID, Friend ID, etc.
  message: { type: String, required: true },
  read: { type: Boolean, default: false }
}, { timestamps: true });

notificationSchema.index({ recipient: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
