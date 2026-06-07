const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String },
  googleId: { type: String },
  username: { type: String, required: true, unique: true },
  gender: { type: String, enum: ['male', 'female'], required: true },
  avatarType: { type: String, enum: ['male_default', 'female_default'] },
  profileImageUrl: { type: String, default: null },
  points: { type: Number, default: 0 },
  streak: { type: Number, default: 0 },
  longestStreak: { type: Number, default: 0 },
  lastCompletedDate: { type: Date },
}, { timestamps: true });

userSchema.index({ username: 1 });
userSchema.index({ email: 1 });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
