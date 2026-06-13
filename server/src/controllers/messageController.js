const Message = require('../models/Message');
const Challenge = require('../models/Challenge');

exports.getMessagesByChallenge = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    const challenge = await Challenge.findById(challengeId);
    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    // Security check: Only creator or recipient can view messages
    if (challenge.creator.toString() !== req.user._id.toString() &&
        challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to view messages for this challenge' });
    }

    const messages = await Message.find({ challenge: challengeId })
      .populate('sender', 'name username profileImageUrl gender avatarType')
      .sort('createdAt');
    res.json(messages);
  } catch (error) {
    next(error);
  }
};

exports.createMessage = async (req, res, next) => {
  try {
    const { content } = req.body;
    const message = await Message.create({
      challenge: req.params.challengeId,
      sender: req.user._id,
      content
    });

    const populatedMessage = await Message.findById(message._id)
      .populate('sender', 'name username profileImageUrl gender avatarType');

    res.status(201).json(populatedMessage);
  } catch (error) {
    next(error);
  }
};
