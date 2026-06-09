const mongoose = require('mongoose');

const friendSchema = new mongoose.Schema({
  requester: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending'
  },
  streak: { type: Number, default: 0 },
  longestStreak: { type: Number, default: 0 },
  lastStreakUpdate: { type: Date },
}, { timestamps: true });

friendSchema.index({ requester: 1, recipient: 1 });
friendSchema.index({ status: 1 });

module.exports = mongoose.model('Friend', friendSchema);
