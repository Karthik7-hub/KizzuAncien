const User = require('../models/User');
const Challenge = require('../models/Challenge');
const Friend = require('../models/Friend');
const PointTransaction = require('../models/PointTransaction');

exports.getProfile = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId);

    const completedChallenges = await Challenge.countDocuments({ recipient: userId, status: 'approved' });
    const failedChallenges = await Challenge.countDocuments({ recipient: userId, status: 'rejected' });
    const activeChallenges = await Challenge.countDocuments({ recipient: userId, status: 'pending' });

    const friendsCount = await Friend.countDocuments({
      status: 'accepted',
      $or: [{ requester: userId }, { recipient: userId }]
    });

    const pointsEarnedResult = await PointTransaction.aggregate([
      { $match: { user: userId, amount: { $gt: 0 } } },
      { $group: { _id: null, total: { $sum: "$amount" } } }
    ]);
    const pointsSpentResult = await PointTransaction.aggregate([
      { $match: { user: userId, amount: { $lt: 0 } } },
      { $group: { _id: null, total: { $sum: { $abs: "$amount" } } } }
    ]);

    res.json({
      user,
      stats: {
        completed: completedChallenges,
        failed: failedChallenges,
        active: activeChallenges,
        friends: friendsCount,
        pointsEarned: pointsEarnedResult[0]?.total || 0,
        pointsSpent: pointsSpentResult[0]?.total || 0,
        streak: user.streak,
        longestStreak: user.longestStreak || user.streak // Fallback if not tracked yet
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    if (user) {
      user.name = req.body.name || user.name;
      user.profileImageUrl = req.body.profileImageUrl || user.profileImageUrl;
      if (req.body.gender) {
        user.gender = req.body.gender;
        user.avatarType = user.gender === 'male' ? 'male_default' : 'female_default';
      }
      const updatedUser = await user.save();
      res.json(updatedUser);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    next(error);
  }
};

exports.searchUsers = async (req, res, next) => {
  try {
    const keyword = req.query.search ? {
      $or: [
        { name: { $regex: req.query.search, $options: 'i' } },
        { username: { $regex: req.query.search, $options: 'i' } },
      ]
    } : {};

    const users = await User.find({ ...keyword, _id: { $ne: req.user._id } })
      .select('name username profileImageUrl gender avatarType points streak')
      .limit(10);
    res.json(users);
  } catch (error) {
    next(error);
  }
};
