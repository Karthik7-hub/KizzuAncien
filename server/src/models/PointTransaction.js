const mongoose = require('mongoose');

const pointTransactionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true }, // positive for gain, negative for spend
  type: {
    type: String,
    enum: ['challenge_reward', 'truth_spend', 'dare_spend', 'bonus'],
    required: true
  },
  description: { type: String },
  relatedId: { type: mongoose.Schema.Types.ObjectId }, // Challenge ID, etc.
}, { timestamps: true });

module.exports = mongoose.model('PointTransaction', pointTransactionSchema);
