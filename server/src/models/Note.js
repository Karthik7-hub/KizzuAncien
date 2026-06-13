const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  challenge: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge', required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String },
  type: {
    type: String,
    enum: ['code', 'explanation', 'image', 'link'],
    required: true
  },
  content: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  order: { type: Number, default: 0 }
}, { timestamps: true });

noteSchema.index({ challenge: 1 });
noteSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Note', noteSchema);
