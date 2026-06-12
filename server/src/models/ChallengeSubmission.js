const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  type: { type: String, enum: ['explanation', 'code', 'image', 'link'], required: true },
  title: { type: String },
  content: { type: String, required: true },
  metadata: { type: Map, of: String }, // e.g., language for code, original filename
  version: { type: Number, default: 1 }
}, { timestamps: true });

const versionSchema = new mongoose.Schema({
  versionNumber: { type: Number, required: true },
  notes: [noteSchema],
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  reviewerNote: { type: String },
  reviewedAt: { type: Date },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

const submissionSchema = new mongoose.Schema({
  challenge: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge', required: true },
  submitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  currentVersion: { type: Number, default: 1 },
  versions: [versionSchema],
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  latestVersionData: { type: Object }, // Store a summary of the latest version for instant render
  versionCount: { type: Number, default: 1 }
}, { timestamps: true });

submissionSchema.index({ challenge: 1 });
submissionSchema.index({ submitter: 1 });
submissionSchema.index({ status: 1 });

module.exports = mongoose.model('ChallengeSubmission', submissionSchema);
