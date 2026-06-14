const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String },
  deadline: { type: Date, required: true },
  proofType: {
    type: String,
    enum: ['any', 'image', 'video', 'text', 'none'],
    default: 'any'
  },
  status: {
    type: String,
    enum: ['pending', 'submitted', 'approved', 'rejected', 'expired'],
    default: 'pending'
  },
  coverImage: { type: String },
  notes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Note' }],
}, { timestamps: true });

challengeSchema.index({ creator: 1 });
challengeSchema.index({ recipient: 1 });
challengeSchema.index({ status: 1 });

module.exports = mongoose.model('Challenge', challengeSchema);
