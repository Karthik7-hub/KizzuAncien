const Challenge = require('../models/Challenge');
const Note = require('../models/Note');
const Message = require('../models/Message');
const ChallengeSubmission = require('../models/ChallengeSubmission');
const User = require('../models/User');
const Friend = require('../models/Friend');
const { createCappedNotification } = require('../utils/notificationUtils');
const PointTransaction = require('../models/PointTransaction');
const { uploadImage } = require('../services/imageKitService');
const { sendPushNotification } = require('../services/firebaseService');

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
    .populate({
      path: 'notes',
      populate: { path: 'createdBy', select: 'name username profileImageUrl gender avatarType' }
    })
    .sort('-createdAt');

    // Fetch submissions and latest messages for these challenges
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    });

    const latestMessages = await Message.aggregate([
      { $match: { challenge: { $in: challengeIds } } },
      { $sort: { createdAt: -1 } },
      { $group: { _id: "$challenge", lastMessage: { $first: "$$ROOT" } } }
    ]);

    // Merge submissions and messages into challenges
    const results = challenges.map(challenge => {
      const submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
      const messageGroup = latestMessages.find(m => m._id.toString() === challenge._id.toString());

      return {
        ...challenge.toObject(),
        submission: submission || null,
        latestMessage: messageGroup ? messageGroup.lastMessage : null,
        unreadCount: 0 // Placeholder for future unread logic
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
    .populate({
      path: 'notes',
      populate: { path: 'createdBy', select: 'name username profileImageUrl gender avatarType' }
    })
    .sort('-createdAt');

    // Fetch submissions and latest messages for these challenges
    const challengeIds = challenges.map(c => c._id);
    const submissions = await ChallengeSubmission.find({
      challenge: { $in: challengeIds }
    });

    const latestMessages = await Message.aggregate([
      { $match: { challenge: { $in: challengeIds } } },
      { $sort: { createdAt: -1 } },
      { $group: { _id: "$challenge", lastMessage: { $first: "$$ROOT" } } }
    ]);

    // Merge submissions and messages into challenges
    const results = challenges.map(challenge => {
      const submission = submissions.find(s => s.challenge.toString() === challenge._id.toString());
      const messageGroup = latestMessages.find(m => m._id.toString() === challenge._id.toString());

      return {
        ...challenge.toObject(),
        submission: submission || null,
        latestMessage: messageGroup ? messageGroup.lastMessage : null,
        unreadCount: 0
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
      .populate('challenge')
      .populate('submitter', 'name username profileImageUrl gender avatarType')
      .populate({
        path: 'selectedNotes',
        populate: { path: 'createdBy', select: 'name username profileImageUrl gender avatarType' }
      });

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

exports.submitProof = async (req, res, next) => {
  try {
    const { challengeId, proofText, proofType, selectedNotes } = req.body;
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

    let parsedNotes = [];
    if (selectedNotes) {
      parsedNotes = typeof selectedNotes === 'string' ? JSON.parse(selectedNotes) : selectedNotes;
    }

    const submission = await ChallengeSubmission.create({
      challenge: challengeId,
      submitter: req.user._id,
      proofUrl,
      proofText,
      proofType,
      selectedNotes: parsedNotes
    });

    challenge.status = 'submitted';
    await challenge.save();

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

    // Award relationship points
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

      // Update recipient's user-level streak metrics
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

      // Also update creator's user-level streak metrics
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

exports.createNote = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    let { title, description, type, content } = req.body;

    // Parse content if it is received as a string (from FormData)
    if (typeof content === 'string') {
      content = JSON.parse(content);
    }

    const challenge = await Challenge.findById(challengeId);
    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    // Authorization: Only creator or recipient can add notes
    if (challenge.creator.toString() !== req.user._id.toString() &&
        challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to add notes to this challenge' });
    }

    // Handle files upload
    if (req.files && req.files.length > 0) {
      const imageUrls = [];
      for (const file of req.files) {
        const uploadResult = await uploadImage(file.buffer, file.originalname);
        imageUrls.push(uploadResult.url);
      }
      if (!content) {
        content = {};
      }
      content.images = imageUrls;
    }

    const note = await Note.create({
      challenge: challengeId,
      createdBy: req.user._id,
      title,
      description,
      type,
      content,
      order: req.body.order || 0
    });

    challenge.notes.push(note._id);
    await challenge.save();

    const populatedNote = await Note.findById(note._id).populate('createdBy', 'name username profileImageUrl gender avatarType');

    res.status(201).json(populatedNote);
  } catch (error) {
    next(error);
  }
};

exports.getNotes = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    const challenge = await Challenge.findById(challengeId);
    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    // Security check: Only creator or recipient can view notes
    if (challenge.creator.toString() !== req.user._id.toString() &&
        challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to view notes for this challenge' });
    }

    const notes = await Note.find({ challenge: challengeId })
      .populate('createdBy', 'name username profileImageUrl gender avatarType')
      .sort('order createdAt');

    res.json(notes);
  } catch (error) {
    next(error);
  }
};

exports.reorderNotes = async (req, res, next) => {
  try {
    const { challengeId } = req.params;
    const { noteOrders } = req.body; // Array of { id, order }

    const challenge = await Challenge.findById(challengeId);
    if (!challenge) {
      return res.status(404).json({ message: 'Challenge not found' });
    }

    if (challenge.creator.toString() !== req.user._id.toString() &&
        challenge.recipient.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const updatePromises = noteOrders.map(no =>
      Note.findByIdAndUpdate(no.id, { order: no.order })
    );

    await Promise.all(updatePromises);
    res.json({ message: 'Notes reordered successfully' });
  } catch (error) {
    next(error);
  }
};

exports.updateNote = async (req, res, next) => {
  try {
    const { challengeId, noteId } = req.params;
    const { title, description } = req.body;
    let { content } = req.body;

    if (typeof content === 'string') {
      content = JSON.parse(content);
    }

    const note = await Note.findById(noteId);
    if (!note) {
      return res.status(404).json({ message: 'Note not found' });
    }

    if (note.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to edit this note' });
    }

    if (req.files && req.files.length > 0) {
      const imageUrls = [];
      for (const file of req.files) {
        const uploadResult = await uploadImage(file.buffer, file.originalname);
        imageUrls.push(uploadResult.url);
      }
      if (!content) {
        content = {};
      }
      content.images = [...(content.images || []), ...imageUrls];
    }

    note.title = title !== undefined ? title : note.title;
    note.description = description !== undefined ? description : note.description;
    note.content = content !== undefined ? content : note.content;
    await note.save();

    const populatedNote = await Note.findById(note._id).populate('createdBy', 'name username profileImageUrl gender avatarType');
    res.json(populatedNote);
  } catch (error) {
    next(error);
  }
};

exports.deleteNote = async (req, res, next) => {
  try {
    const { challengeId, noteId } = req.params;
    const note = await Note.findById(noteId);
    if (!note) {
      return res.status(404).json({ message: 'Note not found' });
    }

    if (note.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this note' });
    }

    await Note.findByIdAndDelete(noteId);

    await Challenge.findByIdAndUpdate(challengeId, {
      $pull: { notes: noteId }
    });

    res.json({ message: 'Note deleted successfully' });
  } catch (error) {
    next(error);
  }
};
