const Challenge = require('../models/Challenge');
const ChallengeSubmission = require('../models/ChallengeSubmission');
const User = require('../models/User');
const Notification = require('../models/Notification');
const PointTransaction = require('../models/PointTransaction');
const { uploadImage } = require('../services/imageKitService');

exports.createChallenge = async (req, res, next) => {
  try {
    const { recipientId, title, description, deadline, proofType } = req.body;
    const challenge = await Challenge.create({
      creator: req.user._id,
      recipient: recipientId,
      title,
      description,
      deadline,
      proofType
    });

    await Notification.create({
      recipient: recipientId,
      sender: req.user._id,
      type: 'challenge_received',
      relatedId: challenge._id,
      message: `${req.user.name} challenged you: ${title}`
    });

    res.status(201).json(challenge);
  } catch (error) {
    next(error);
  }
};

exports.getChallenges = async (req, res, next) => {
  try {
    const challenges = await Challenge.find({
      $or: [{ creator: req.user._id }, { recipient: req.user._id }]
    })
    .populate('creator recipient', 'name username profileImageUrl gender avatarType')
    .sort('-createdAt');
    res.json(challenges);
  } catch (error) {
    next(error);
  }
};

exports.getSubmissionByChallenge = async (req, res, next) => {
  try {
    const submission = await ChallengeSubmission.findOne({ challenge: req.params.challengeId })
      .populate('submitter', 'name username profileImageUrl gender avatarType');
    if (!submission) {
      return res.status(404).json({ message: 'Submission not found' });
    }
    res.json(submission);
  } catch (error) {
    next(error);
  }
};

exports.submitProof = async (req, res, next) => {
  try {
    const { challengeId, proofText, proofType } = req.body;
    const challenge = await Challenge.findById(challengeId);

    if (!challenge || challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    let proofUrl = req.body.proofUrl;

    if (req.file) {
      const uploadResult = await uploadImage(req.file.buffer, req.file.originalname);
      proofUrl = uploadResult.url;
    }

    const submission = await ChallengeSubmission.create({
      challenge: challengeId,
      submitter: req.user._id,
      proofUrl,
      proofText,
      proofType
    });

    challenge.status = 'submitted';
    await challenge.save();

    await Notification.create({
      recipient: challenge.creator,
      sender: req.user._id,
      type: 'submission_received',
      relatedId: submission._id,
      message: `${req.user.name} submitted proof for: ${challenge.title}`
    });

    res.status(201).json(submission);
  } catch (error) {
    next(error);
  }
};

exports.reviewSubmission = async (req, res, next) => {
  try {
    const { submissionId, status } = req.body; // 'approved' or 'rejected'
    const submission = await ChallengeSubmission.findById(submissionId).populate('challenge');

    if (!submission) {
      // If submissionId is actually challengeId (fallback for UI simplicity)
      const sub = await ChallengeSubmission.findOne({ challenge: submissionId }).populate('challenge');
      if (sub) {
        return handleReview(sub, status, req, res);
      }
      return res.status(404).json({ message: 'Submission not found' });
    }

    return handleReview(submission, status, req, res);
  } catch (error) {
    next(error);
  }
};

async function handleReview(submission, status, req, res) {
  if (submission.challenge.creator.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Not authorized to review this submission' });
  }

  if (submission.status !== 'pending') {
    return res.status(400).json({ message: 'Submission has already been reviewed' });
  }

  submission.status = status;
  await submission.save();

  const challenge = submission.challenge;
  challenge.status = status;
  await challenge.save();

  if (status === 'approved') {
    const points = 100;
    const recipient = await User.findById(challenge.recipient);
    recipient.points += points;

    const today = new Date().setHours(0,0,0,0);
    const lastCompleted = recipient.lastCompletedDate ? new Date(recipient.lastCompletedDate).setHours(0,0,0,0) : null;

    if (!lastCompleted || today > lastCompleted) {
      recipient.streak = (lastCompleted && today - lastCompleted === 86400000) ? recipient.streak + 1 : 1;
      recipient.lastCompletedDate = new Date();
    }

    await recipient.save();

    await PointTransaction.create({
      user: recipient._id,
      amount: points,
      type: 'challenge_reward',
      relatedId: challenge._id,
      description: `Reward for completing: ${challenge.title}`
    });
  }

  await Notification.create({
    recipient: challenge.recipient,
    sender: req.user._id,
    type: status === 'approved' ? 'challenge_approved' : 'challenge_rejected',
    relatedId: challenge._id,
    message: `Your proof for "${challenge.title}" was ${status}`
  });

  res.json({ submission, challenge });
}
