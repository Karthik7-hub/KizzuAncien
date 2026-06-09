const Message = require('../models/Message');

exports.getMessagesByChallenge = async (req, res, next) => {
  try {
    const messages = await Message.find({ challenge: req.params.challengeId })
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
