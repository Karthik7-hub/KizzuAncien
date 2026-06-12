const Message = require('../models/Message');
const Challenge = require('../models/Challenge');

exports.getMessagesByChallenge = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    const messages = await Message.find({ challenge: challengeId })
      .populate('sender', 'name username profileImageUrl gender avatarType')
      .sort('createdAt');

    // Reset unread count for this user
    await Challenge.findByIdAndUpdate(challengeId, {
      $set: { [`unreadCount.${req.user._id}`]: 0 }
    });

    res.json(messages);
  } catch (error) {
    next(error);
  }
};

exports.createMessage = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    const { content } = req.body;
    const message = await Message.create({
      challenge: challengeId,
      sender: req.user._id,
      content
    });

    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'name username profileImageUrl gender avatarType');

    // Update challenge metadata for preview
    const challenge = await Challenge.findById(challengeId);
    if (challenge) {
      challenge.lastMessage = content;
      challenge.lastMessageAt = new Date();
      challenge.lastMessageBy = req.user._id;

      // Increment unread for the OTHER person in the challenge
      const otherUserId = challenge.creator.toString() === req.user._id.toString()
        ? challenge.recipient.toString()
        : challenge.creator.toString();

      const currentUnread = challenge.unreadCount.get(otherUserId) || 0;
      challenge.unreadCount.set(otherUserId, currentUnread + 1);

      await challenge.save();
    }

    res.status(201).json(populatedMessage);
  } catch (error) {
    next(error);
  }
};
