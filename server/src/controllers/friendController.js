const Friend = require('../models/Friend');
const User = require('../models/User');
const Challenge = require('../models/Challenge');
const { createCappedNotification } = require('../utils/notificationUtils');
const { sendPushNotification } = require('../services/firebaseService');

exports.sendRequest = async (req, res, next) => {
  try {
    const { recipientId } = req.body;
    if (req.user._id.toString() === recipientId) {
      return res.status(400).json({ message: 'You cannot add yourself' });
    }

    const existingRequest = await Friend.findOne({
      $or: [
        { requester: req.user._id, recipient: recipientId },
        { requester: recipientId, recipient: req.user._id }
      ]
    });

    if (existingRequest) {
      return res.status(400).json({ message: 'Request already exists or you are already friends' });
    }

    const friendRequest = await Friend.create({
      requester: req.user._id,
      recipient: recipientId
    });

    await createCappedNotification({
      recipient: recipientId,
      sender: req.user._id,
      type: 'friend_request',
      relatedId: friendRequest._id,
      message: `${req.user.name} sent a friend request`
    });

    // Send Push Notification
    const recipient = await User.findById(recipientId);
    if (recipient && recipient.fcmToken) {
      await sendPushNotification(
        recipient.fcmToken,
        'Connect',
        `From ${req.user.name}\nTap to respond`,
        { type: 'friend_request', id: friendRequest._id.toString() }
      );
    }

    res.status(201).json(friendRequest);
  } catch (error) {
    next(error);
  }
};

exports.respondToRequest = async (req, res, next) => {
  try {
    const { requestId, status } = req.body; // status: 'accepted' or 'rejected'
    const friendRequest = await Friend.findById(requestId);

    if (!friendRequest || friendRequest.recipient.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Request not found' });
    }

    friendRequest.status = status;
    await friendRequest.save();

    if (status === 'accepted') {
      await createCappedNotification({
        recipient: friendRequest.requester,
        sender: req.user._id,
        type: 'friend_request_accepted',
        message: `${req.user.name} accepted friend request`
      });

      // Send Push Notification
      const requester = await User.findById(friendRequest.requester);
      if (requester && requester.fcmToken) {
        await sendPushNotification(
          requester.fcmToken,
          'Connected',
          `${req.user.name} accepted your request`,
          { type: 'friend_request_accepted', id: friendRequest._id.toString() }
        );
      }
    }

    res.json(friendRequest);
  } catch (error) {
    next(error);
  }
};

exports.getFriends = async (req, res, next) => {
  try {
    const userId = req.user._id;

    // Accepted friends
    const friends = await Friend.find({
      $or: [
        { requester: userId, status: 'accepted' },
        { recipient: userId, status: 'accepted' }
      ]
    }).populate('requester recipient', 'name username profileImageUrl gender avatarType');

    // Fetch latest completed challenge for each friend
    const friendList = await Promise.all(friends.map(async f => {
      const isRequester = f.requester._id.toString() === userId.toString();
      const friend = isRequester ? f.recipient.toObject() : f.requester.toObject();
      const friendId = friend._id;

      const todayStart = new Date().setHours(0,0,0,0);
      const yesterdayStart = todayStart - 86400000;
      if (f.streak > 0 && f.lastStreakUpdate && new Date(f.lastStreakUpdate) < new Date(yesterdayStart)) {
        f.streak = 0;
        await f.save();

        const updateStreakForUser = async (uId) => {
          const allUserFriendships = await Friend.find({
            status: 'accepted',
            $or: [{ requester: uId }, { recipient: uId }]
          });
          const bestUserStreak = Math.max(...allUserFriendships.map(fs => fs.streak), 0);
          await User.findByIdAndUpdate(uId, { $set: { currentStreak: bestUserStreak } });
        };
        await updateStreakForUser(userId);
        await updateStreakForUser(friendId);
      }

      const lastChallenge = await Challenge.findOne({
        status: 'approved',
        $or: [
          { creator: userId, recipient: friendId },
          { creator: friendId, recipient: userId }
        ]
      }).sort('-updatedAt');

      return {
        ...friend,
        sharedStreak: f.streak,
        longestSharedStreak: f.longestStreak,
        lastStreakUpdate: f.lastStreakUpdate,
        lastChallengeCompletedAt: lastChallenge ? lastChallenge.updatedAt : null,
        relationshipPoints: isRequester ? f.pointsRequester : f.pointsRecipient
      };
    }));

    // Incoming requests (Pending)
    const incoming = await Friend.find({
      recipient: userId,
      status: 'pending'
    }).populate('requester', 'name username profileImageUrl gender avatarType');

    // Outgoing requests (Pending)
    const outgoing = await Friend.find({
      requester: userId,
      status: 'pending'
    }).populate('recipient', 'name username profileImageUrl gender avatarType');

    res.json({
      friends: friendList,
      incoming: incoming.map(i => ({
        id: i._id,
        user: i.requester
      })),
      outgoing: outgoing.map(o => ({
        id: o._id,
        user: o.recipient
      }))
    });
  } catch (error) {
    next(error);
  }
};

exports.removeFriend = async (req, res, next) => {
  try {
    const { friendId } = req.params;
    await Friend.findOneAndDelete({
      $or: [
        { requester: req.user._id, recipient: friendId },
        { requester: friendId, recipient: req.user._id }
      ]
    });
    res.json({ message: 'Friend removed' });
  } catch (error) {
    next(error);
  }
};

exports.cancelRequest = async (req, res, next) => {
  try {
    const { requestId } = req.params;
    const friendRequest = await Friend.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({ message: 'Request not found' });
    }

    if (friendRequest.requester.toString() !== req.user._id.toString() &&
        friendRequest.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    await Friend.findByIdAndDelete(requestId);
    res.json({ message: 'Request cancelled/removed' });
  } catch (error) {
    next(error);
  }
};
