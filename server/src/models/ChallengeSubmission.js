const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  challenge: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge', required: true },
  submitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  proofUrl: { type: String }, // Image/Video URL
  proofText: { type: String },
  proofType: { type: String, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' }
}, { timestamps: true });

module.exports = mongoose.model('ChallengeSubmission', submissionSchema);
