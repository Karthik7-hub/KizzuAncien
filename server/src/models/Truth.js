const mongoose = require('mongoose');

const truthSchema = new mongoose.Schema({
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  question: { type: String, required: true },
  answer: { type: String },
  pointsSpent: { type: Number, default: 50 },
  status: { type: String, enum: ['pending', 'answered'], default: 'pending' }
}, { timestamps: true });

module.exports = mongoose.model('Truth', truthSchema);
