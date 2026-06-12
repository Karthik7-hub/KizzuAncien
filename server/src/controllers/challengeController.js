const Challenge = require('../models/Challenge');
const ChallengeSubmission = require('../models/ChallengeSubmission');
const ChallengeActivity = require('../models/ChallengeActivity');
const User = require('../models/User');
const Friend = require('../models/Friend');
const { createCappedNotification } = require('../utils/notificationUtils');
const PointTransaction = require('../models/PointTransaction');
const { uploadImage } = require('../services/imageKitService');
const { sendPushNotification } = require('../services/firebaseService');
const { getLatestVersionSummary } = require('../utils/submissionUtils');

exports.createChallenge = async (req, res, next) => {
  try {
    const { recipientId, title, description, deadline, proofType, coverImage } = req.body;
    const challenge = await Challenge.create({
      creator: req.user._id,
      recipient: recipientId,
      title,
      description,
      deadline,
      proofType,
      coverImage
    });

    await createCappedNotification({
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
    .populate('lastMessageBy', 'name')
    .sort('-createdAt');

    // Fetch submissions for these challenges (only summary fields)
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    }).select('challenge currentVersion status latestVersionData versionCount');

    // Merge submissions into challenges
    const results = challenges.map(challenge => {
      let submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
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

    // Fetch submissions for these challenges and populate version authors
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    }).populate('versions.createdBy', 'name username profileImageUrl gender avatarType');

    // Merge submissions into challenges
    const results = await Promise.all(challenges.map(async challenge => {
      let submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
      return {
        ...challenge.toObject(),
        submission: submission || null
      };
    }));

    res.json(results);
  } catch (error) {
    next(error);
  }
};

exports.getSubmissionByChallenge = async (req, res, next) => {
  try {
    const submission = await ChallengeSubmission.findOne({ challenge: req.params.challengeId })
      .populate('challenge')
      .populate('submitter', 'name username profileImageUrl gender avatarType')
      .populate('versions.createdBy', 'name username profileImageUrl gender avatarType');

    if (!submission) {
      return res.status(404).json({ message: 'Submission not found' });
    }

    // Security check: Only creator or recipient can view the submission
    if (submission.challenge.creator.toString() !== req.user._id.toString() &&
        submission.challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to view this submission' });
    }

    res.json(submission);
  } catch (error) {
    next(error);
  }
};

exports.uploadAttachment = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file provided' });
    }
    const uploadResult = await uploadImage(req.file.buffer, req.file.originalname);
    res.json({ url: uploadResult.url });
  } catch (error) {
    next(error);
  }
};

exports.submitProof = async (req, res, next) => {
  try {
    const { challengeId, notes } = req.body;
    const challenge = await Challenge.findById(challengeId);

    if (!challenge || challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Challenge not found or not authorized' });
    }

    let submission = await ChallengeSubmission.findOne({ challenge: challengeId, submitter: req.user._id });

    if (submission) {
      return res.status(400).json({ message: 'Submission already exists. Use edit instead.' });
    }

    const parsedNotes = typeof notes === 'string' ? JSON.parse(notes) : notes;

    const initialVersion = {
      versionNumber: 1,
      notes: parsedNotes,
      status: 'pending',
      createdBy: req.user._id
    };

    submission = await ChallengeSubmission.create({
      challenge: challengeId,
      submitter: req.user._id,
      currentVersion: 1,
      versions: [initialVersion],
      status: 'pending',
      versionCount: 1,
      latestVersionData: getLatestVersionSummary(initialVersion)
    });

    await submission.populate('versions.createdBy', 'name username profileImageUrl gender avatarType');

    challenge.status = 'submitted';
    await challenge.save();

    // Log Activity
    await ChallengeActivity.create({
      challenge: challengeId,
      user: req.user._id,
      type: 'submission_created',
      versionNumber: 1,
      message: `${req.user.name} created submission v1`
    });

    await createCappedNotification({
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

exports.editSubmission = async (req, res, next) => {
  try {
    const { submissionId, notes } = req.body;
    const submission = await ChallengeSubmission.findById(submissionId).populate('challenge');

    if (!submission || submission.submitter.toString() !== req.user._id.toString()) {
      return res.status(404).json({ message: 'Submission not found or not authorized' });
    }

    const parsedNotes = typeof notes === 'string' ? JSON.parse(notes) : notes;
    const nextVersionNumber = submission.currentVersion + 1;

    const newVersion = {
      versionNumber: nextVersionNumber,
      notes: parsedNotes,
      status: 'pending',
      createdBy: req.user._id
    };

    submission.versions.push(newVersion);
    submission.currentVersion = nextVersionNumber;
    submission.status = 'pending';
    submission.versionCount = submission.versions.length;
    submission.latestVersionData = getLatestVersionSummary(newVersion);
    await submission.save();

    await submission.populate('versions.createdBy', 'name username profileImageUrl gender avatarType');

    const challenge = submission.challenge;
    challenge.status = 'submitted';
    await challenge.save();

    // Log Activity
    await ChallengeActivity.create({
      challenge: challenge._id,
      user: req.user._id,
      type: 'submission_edited',
      versionNumber: nextVersionNumber,
      message: `${req.user.name} updated submission to v${nextVersionNumber}`
    });

    await createCappedNotification({
      recipient: challenge.creator,
      sender: req.user._id,
      type: 'submission_received',
      relatedId: submission._id,
      message: `${req.user.name} updated verification for ${challenge.title}`
    });

    res.json(submission);
  } catch (error) {
    next(error);
  }
};

exports.getChallengeActivities = async (req, res, next) => {
  try {
    const activities = await ChallengeActivity.find({ challenge: req.params.challengeId })
      .populate('user', 'name profileImageUrl')
      .sort('-createdAt');
    res.json(activities);
  } catch (error) {
    next(error);
  }
};

exports.reviewSubmission = async (req, res, next) => {
  try {
    const { submissionId, status, versionNumber, reviewerNote } = req.body;
    const submission = await ChallengeSubmission.findById(submissionId).populate('challenge');

    if (!submission) {
      return res.status(404).json({ message: 'Submission not found' });
    }

    const version = submission.versions.find(v => v.versionNumber === versionNumber);
    if (!version) {
      return res.status(404).json({ message: 'Version not found' });
    }

    if (submission.challenge.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to review this submission' });
    }

    if (version.status !== 'pending') {
      return res.status(400).json({ message: 'Version has already been reviewed' });
    }

    version.status = status;
    version.reviewerNote = reviewerNote;
    version.reviewedAt = new Date();

    if (versionNumber === submission.currentVersion) {
      submission.status = status;
      submission.latestVersionData = getLatestVersionSummary(version);
    }

    await submission.save();

    const challenge = submission.challenge;
    if (submission.status === 'approved') {
       challenge.status = 'approved';
    } else if (submission.status === 'rejected' && versionNumber === submission.currentVersion) {
       challenge.status = 'rejected';
    }
    await challenge.save();

    // Log Activity
    await ChallengeActivity.create({
      challenge: challenge._id,
      user: req.user._id,
      type: status === 'approved' ? 'approved' : 'rejected',
      versionNumber: versionNumber,
      message: `${req.user.name} ${status} submission v${versionNumber}`
    });

    if (status === 'approved' && versionNumber === submission.currentVersion) {
      const points = 5;
      const friendRel = await Friend.findOne({
        $or: [
          { requester: challenge.creator, recipient: challenge.recipient },
          { requester: challenge.recipient, recipient: challenge.creator }
        ],
        status: 'accepted'
      });

      if (friendRel) {
        if (friendRel.requester.toString() === challenge.recipient.toString()) {
          friendRel.pointsRequester += points;
        } else {
          friendRel.pointsRecipient += points;
        }

        const today = new Date().setHours(0,0,0,0);
        const lastUpdate = friendRel.lastStreakUpdate ? new Date(friendRel.lastStreakUpdate).setHours(0,0,0,0) : null;

        if (!lastUpdate || today > lastUpdate) {
          const yesterday = today - 86400000;
          const twoDaysAgo = today - (86400000 * 2);

          if (lastUpdate === yesterday || lastUpdate === twoDaysAgo) {
            friendRel.streak += 1;
          } else {
            friendRel.streak = 1;
          }

          friendRel.lastStreakUpdate = new Date();
          if (friendRel.streak > (friendRel.longestStreak || 0)) {
            friendRel.longestStreak = friendRel.streak;
          }
        }
        await friendRel.save();

        const allRecipientFriendships = await Friend.find({
          $or: [{ requester: challenge.recipient }, { recipient: challenge.recipient }],
          status: 'accepted'
        });

        const recipient = await User.findById(challenge.recipient);
        const bestCurrentStreak = Math.max(...allRecipientFriendships.map(f => f.streak), 0);
        recipient.currentStreak = bestCurrentStreak;
        if (bestCurrentStreak > (recipient.longestStreak || 0)) {
          recipient.longestStreak = bestCurrentStreak;
        }
        await recipient.save();

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

      await PointTransaction.create({
        user: challenge.recipient,
        amount: points,
        type: 'challenge_reward',
        relatedId: challenge._id,
        description: `Reward for completing: ${challenge.title}`
      });
    }

    await createCappedNotification({
      recipient: challenge.recipient,
      sender: req.user._id,
      type: status === 'approved' ? 'challenge_approved' : 'challenge_rejected',
      relatedId: challenge._id,
      message: status === 'approved'
        ? `Verification for "${challenge.title}" approved`
        : `Verification for "${challenge.title}" declined`
    });

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
  } catch (error) {
    next(error);
  }
};
