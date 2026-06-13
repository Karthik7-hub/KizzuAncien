const Challenge = require('../models/Challenge');
const ChallengeSubmission = require('../models/ChallengeSubmission');
const User = require('../models/User');
const Friend = require('../models/Friend');
const Notification = require('../models/Notification');
const PointTransaction = require('../models/PointTransaction');
const { uploadImage } = require('../services/imageKitService');
const { sendPushNotification } = require('../services/firebaseService');

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
      message: `${req.user.name} sent a challenge: ${title}`
    });

    // Send Push Notification
    const recipient = await User.findById(recipientId);
    if (recipient && recipient.fcmToken) {
      await sendPushNotification(
        recipient.fcmToken,
        'Challenge',
        `${title}\nFrom ${req.user.name}`,
        { type: 'challenge_received', id: challenge._id.toString() }
      );
    }

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

    // Fetch submissions for these challenges and merge them
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    });

    const results = challenges.map(challenge => {
      const submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
      return {
        ...challenge.toObject(),
        submission: submission || null
      };
    });

    res.json(results);
  } catch (error) {
    next(error);
  }
};

exports.getSharedChallenges = async (req, res, next) => {
  try {
    const { friendId } = req.params;
    const userId = req.user._id;

    const challenges = await Challenge.find({
      $or: [
        { creator: userId, recipient: friendId },
        { creator: friendId, recipient: userId }
      ]
    })
    .populate('creator recipient', 'name username profileImageUrl gender avatarType')
    .sort('-createdAt');

    // Fetch submissions for these challenges
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    });

    // Merge submissions into challenges
    const results = challenges.map(challenge => {
      const submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
      return {
        ...challenge.toObject(),
        submission: submission || null
      };
    });

    res.json(results);
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

    if (challenge.status !== 'pending') {
      return res.status(400).json({ message: 'Challenge is not in a pending state' });
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
      message: `${req.user.name} submitted verification for ${challenge.title}`
    });

    // Send Push Notification
    const creator = await User.findById(challenge.creator);
    if (creator && creator.fcmToken) {
      await sendPushNotification(
        creator.fcmToken,
        'Verification',
        `${challenge.title}\nSubmitted by ${req.user.name}`,
        { type: 'submission_received', id: submission._id.toString() }
      );
    }

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
    const points = 5;
    const recipient = await User.findById(challenge.recipient);
    recipient.points += points;
    await recipient.save();

    // Relationship-based Streak Logic
    const friendRel = await Friend.findOne({
      $or: [
        { requester: challenge.creator, recipient: challenge.recipient },
        { requester: challenge.recipient, recipient: challenge.creator }
      ],
      status: 'accepted'
    });

    if (friendRel) {
      const today = new Date().setHours(0,0,0,0);
      const lastUpdate = friendRel.lastStreakUpdate ? new Date(friendRel.lastStreakUpdate).setHours(0,0,0,0) : null;

      if (!lastUpdate || today > lastUpdate) {
        const yesterday = today - 86400000;
        if (lastUpdate === yesterday) {
          friendRel.streak += 1;
        } else {
          friendRel.streak = 1;
        }

        friendRel.lastStreakUpdate = new Date();
        if (friendRel.streak > (friendRel.longestStreak || 0)) {
          friendRel.longestStreak = friendRel.streak;
        }
        await friendRel.save();

        // Update recipient's user-level streak metrics
        const allRecipientFriendships = await Friend.find({
          $or: [{ requester: challenge.recipient }, { recipient: challenge.recipient }],
          status: 'accepted'
        });

        const bestCurrentStreak = Math.max(...allRecipientFriendships.map(f => f.streak), 0);
        recipient.currentStreak = bestCurrentStreak;
        if (bestCurrentStreak > (recipient.longestStreak || 0)) {
          recipient.longestStreak = bestCurrentStreak;
        }
        await recipient.save();

        // Also update creator's user-level streak metrics (since streaks are mutual)
        const creator = await User.findById(challenge.creator);
        if (creator) {
          const allCreatorFriendships = await Friend.find({
            $or: [{ requester: challenge.creator }, { recipient: challenge.creator }],
            status: 'accepted'
          });
          const creatorBestStreak = Math.max(...allCreatorFriendships.map(f => f.streak), 0);
          creator.currentStreak = creatorBestStreak;
          if (creatorBestStreak > (creator.longestStreak || 0)) {
            creator.longestStreak = creatorBestStreak;
          }
          await creator.save();
        }
      }
    }

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
    message: status === 'approved'
      ? `Verification for "${challenge.title}" approved`
      : `Verification for "${challenge.title}" declined`
  });

  // Send Push Notification
  const recipient = await User.findById(challenge.recipient);
  if (recipient && recipient.fcmToken) {
    await sendPushNotification(
      recipient.fcmToken,
      status === 'approved' ? 'Approved' : 'Declined',
      status === 'approved'
        ? `${challenge.title}\nVerification accepted`
        : `${challenge.title}\nVerification declined`,
      { type: status === 'approved' ? 'challenge_approved' : 'challenge_rejected', id: challenge._id.toString() }
    );
  }

  res.json({ submission, challenge });
}
