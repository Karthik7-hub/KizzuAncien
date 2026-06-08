const Truth = require('../models/Truth');
const Dare = require('../models/Dare');
const User = require('../models/User');
const Notification = require('../models/Notification');
const PointTransaction = require('../models/PointTransaction');

exports.sendTruth = async (req, res, next) => {
  try {
    const { recipientId, question } = req.body;
    const pointsRequired = 50;

    const user = await User.findById(req.user._id);
    if (user.points < pointsRequired) {
      return res.status(400).json({ message: 'Insufficient points' });
    }

    const truth = await Truth.create({
      sender: req.user._id,
      recipient: recipientId,
      question,
      pointsSpent: pointsRequired
    });

    user.points -= pointsRequired;
    await user.save();

    await PointTransaction.create({
      user: req.user._id,
      amount: -pointsRequired,
      type: 'truth_spend',
      relatedId: truth._id,
      description: `Sent truth to ${recipientId}`
    });

    await Notification.create({
      recipient: recipientId,
      sender: req.user._id,
      type: 'truth_received',
      relatedId: truth._id,
      message: `${req.user.name} sent a truth question`
    });

    res.status(201).json(truth);
  } catch (error) {
    next(error);
  }
};

exports.sendDare = async (req, res, next) => {
  try {
    const { recipientId, task } = req.body;
    const pointsRequired = 100;

    const user = await User.findById(req.user._id);
    if (user.points < pointsRequired) {
      return res.status(400).json({ message: 'Insufficient points' });
    }

    const dare = await Dare.create({
      sender: req.user._id,
      recipient: recipientId,
      task,
      pointsSpent: pointsRequired
    });

    user.points -= pointsRequired;
    await user.save();

    await PointTransaction.create({
      user: req.user._id,
      amount: -pointsRequired,
      type: 'dare_spend',
      relatedId: dare._id,
      description: `Sent dare to ${recipientId}`
    });

    await Notification.create({
      recipient: recipientId,
      sender: req.user._id,
      type: 'dare_received',
      relatedId: dare._id,
      message: `${req.user.name} sent a dare task`
    });

    res.status(201).json(dare);
  } catch (error) {
    next(error);
  }
};

exports.getTruthsAndDares = async (req, res, next) => {
  try {
    const truths = await Truth.find({
      $or: [{ sender: req.user._id }, { recipient: req.user._id }]
    }).populate('sender recipient', 'name username profileImageUrl gender avatarType');

    const dares = await Dare.find({
      $or: [{ sender: req.user._id }, { recipient: req.user._id }]
    }).populate('sender recipient', 'name username profileImageUrl gender avatarType');

    res.json({ truths, dares });
  } catch (error) {
    next(error);
  }
};
