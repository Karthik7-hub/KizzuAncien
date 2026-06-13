const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String },
  googleId: { type: String },
  username: { type: String, required: true, unique: true },
  gender: { type: String, enum: ['male', 'female', 'other'], default: 'male' },
  avatarType: { type: String, enum: ['male_default', 'female_default'], default: 'male_default' },
  profileImageUrl: { type: String, default: null },
  currentStreak: { type: Number, default: 0 },
  longestStreak: { type: Number, default: 0 },
  lastCompletedDate: { type: Date },
  fcmToken: { type: String, default: null },
  preferences: {
    notifications: {
      challenges: { type: Boolean, default: true },
      friendRequests: { type: Boolean, default: true },
      approvals: { type: Boolean, default: true },
      streaks: { type: Boolean, default: true }
    },
    privacy: {
      allowFriendRequests: { type: Boolean, default: true },
      allowChallengeRequests: { type: Boolean, default: true },
      profileVisibility: { type: String, enum: ['public', 'friends', 'private'], default: 'friends' }
    },
    appearance: {
      theme: { type: String, enum: ['system', 'light', 'dark'], default: 'dark' }
    }
  }
}, { timestamps: true });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
