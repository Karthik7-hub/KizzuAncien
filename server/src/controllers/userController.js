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

    const allFriendships = await Friend.find({
      status: 'accepted',
      $or: [{ requester: userId }, { recipient: userId }]
    }).populate('requester recipient', 'name');

    let longestOverallStreak = 0;
    let streakFriendName = '';
    let activeStreaksCount = 0;

    allFriendships.forEach(f => {
      if (f.streak > 0) activeStreaksCount++;
      // We use historical longestStreak from the relationship
      if (f.longestStreak > longestOverallStreak) {
        longestOverallStreak = f.longestStreak;
        const otherUser = f.requester._id.toString() === userId.toString() ? f.recipient : f.requester;
        streakFriendName = otherUser.name;
      }
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
        streak: user.currentStreak,
        longestStreak: user.longestStreak
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

exports.updateFcmToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    const user = await User.findById(req.user._id);
    if (user) {
      user.fcmToken = fcmToken;
      await user.save();
      res.json({ message: 'FCM Token updated successfully' });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    next(error);
  }
};

exports.getUserProfile = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const relationship = await Friend.findOne({
      $or: [
        { requester: req.user._id, recipient: userId },
        { requester: userId, recipient: req.user._id }
      ]
    });

    let relationshipStatus = 'NOT_FRIENDS';
    if (relationship) {
      if (relationship.status === 'accepted') {
        relationshipStatus = 'FRIENDS';
      } else if (relationship.status === 'pending') {
        relationshipStatus = relationship.requester.toString() === req.user._id.toString()
          ? 'PENDING_SENT'
          : 'PENDING_RECEIVED';
      }
    }

    res.json({
      user,
      relationshipStatus,
      requestId: relationship ? relationship._id : null
    });
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
