const Truth = require('../models/Truth');
const Dare = require('../models/Dare');
const User = require('../models/User');
const { createCappedNotification } = require('../utils/notificationUtils');
const PointTransaction = require('../models/PointTransaction');
const { sendPushNotification } = require('../services/firebaseService');

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

    await createCappedNotification({
      recipient: recipientId,
      sender: req.user._id,
      type: 'truth_received',
      relatedId: truth._id,
      message: `${req.user.name} sent a truth question`
    });

    // Send Push Notification
    const recipient = await User.findById(recipientId);
    if (recipient && recipient.fcmToken) {
      await sendPushNotification(
        recipient.fcmToken,
        'Truth',
        `From ${req.user.name}\nTap to view`,
        { type: 'truth_received', id: truth._id.toString() }
      );
    }

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

    await createCappedNotification({
      recipient: recipientId,
      sender: req.user._id,
      type: 'dare_received',
      relatedId: dare._id,
      message: `${req.user.name} sent a dare task`
    });

    // Send Push Notification
    const recipient = await User.findById(recipientId);
    if (recipient && recipient.fcmToken) {
      await sendPushNotification(
        recipient.fcmToken,
        'Dare',
        `From ${req.user.name}\nTap to view`,
        { type: 'dare_received', id: dare._id.toString() }
      );
    }

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

exports.answerTruth = async (req, res, next) => {
  try {
    const { truthId, answer } = req.body;
    const truth = await Truth.findById(truthId).populate('sender');
    if (!truth || truth.recipient.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Truth question not found' });
    }

    truth.answer = answer;
    truth.status = 'answered';
    await truth.save();

    await createCappedNotification({
      recipient: truth.sender._id,
      sender: req.user._id,
      type: 'truth_answered',
      relatedId: truth._id,
      message: `${req.user.name} answered your truth question`
    });

    if (truth.sender.fcmToken) {
      await sendPushNotification(
        truth.sender.fcmToken,
        'Truth Answered',
        `${req.user.name} replied to your truth`,
        { type: 'truth_answered', id: truth._id.toString() }
      );
    }

    res.json(truth);
  } catch (error) {
    next(error);
  }
};

exports.completeDare = async (req, res, next) => {
  try {
    const { dareId } = req.body;
    const dare = await Dare.findById(dareId).populate('sender');
    if (!dare || dare.recipient.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Dare task not found' });
    }

    // Optional: handle proof image if you want to support it for dares too
    // For now, simple completion
    dare.status = 'completed';
    await dare.save();

    await createCappedNotification({
      recipient: dare.sender._id,
      sender: req.user._id,
      type: 'dare_completed',
      relatedId: dare._id,
      message: `${req.user.name} completed your dare task`
    });

    if (dare.sender.fcmToken) {
      await sendPushNotification(
        dare.sender.fcmToken,
        'Dare Completed',
        `${req.user.name} finished the dare`,
        { type: 'dare_completed', id: dare._id.toString() }
      );
    }

    res.json(dare);
  } catch (error) {
    next(error);
  }
};
