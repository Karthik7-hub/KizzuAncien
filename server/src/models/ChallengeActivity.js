const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
  challenge: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge', required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: {
    type: String,
    enum: ['submission_created', 'submission_edited', 'approved', 'rejected', 'resubmitted'],
    required: true
  },
  versionNumber: { type: Number },
  message: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('ChallengeActivity', activitySchema);
