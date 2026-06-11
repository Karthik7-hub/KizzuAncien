const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const User = require('../models/User');
const Friend = require('../models/Friend');
const Challenge = require('../models/Challenge');
const Truth = require('../models/Truth');
const Dare = require('../models/Dare');

async function migrate() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB...');

    // 1. Reset all relationship points to start clean
    await Friend.updateMany({}, { pointsRequester: 0, pointsRecipient: 0 });
    console.log('Reset all relationship points to 0.');

    // 2. Migrate Challenge Rewards
    // Points go to the recipient of an approved challenge
    const approvedChallenges = await Challenge.find({ status: 'approved' });
    console.log(`Found ${approvedChallenges.length} approved challenges.`);

    for (const challenge of approvedChallenges) {
      const rel = await Friend.findOne({
        $or: [
          { requester: challenge.creator, recipient: challenge.recipient },
          { requester: challenge.recipient, recipient: challenge.creator }
        ],
        status: 'accepted'
      });

      if (rel) {
        // Recipient earns 5 points
        if (rel.requester.toString() === challenge.recipient.toString()) {
          rel.pointsRequester += 5;
        } else {
          rel.pointsRecipient += 5;
        }
        await rel.save();
      }
    }
    console.log('Migrated challenge rewards.');

    // 3. Migrate Truth Spendings
    // Points are deducted from the sender's relationship balance
    const truths = await Truth.find({});
    console.log(`Found ${truths.length} truth questions.`);
    for (const truth of truths) {
      const rel = await Friend.findOne({
        $or: [
          { requester: truth.sender, recipient: truth.recipient },
          { requester: truth.recipient, recipient: truth.sender }
        ],
        status: 'accepted'
      });

      if (rel) {
        if (rel.requester.toString() === truth.sender.toString()) {
          rel.pointsRequester -= 50;
        } else {
          rel.pointsRecipient -= 50;
        }
        await rel.save();
      }
    }

    // 4. Migrate Dare Spendings
    const dares = await Dare.find({});
    console.log(`Found ${dares.length} dare tasks.`);
    for (const dare of dares) {
      const rel = await Friend.findOne({
        $or: [
          { requester: dare.sender, recipient: dare.recipient },
          { requester: dare.recipient, recipient: dare.sender }
        ],
        status: 'accepted'
      });

      if (rel) {
        if (rel.requester.toString() === dare.sender.toString()) {
          rel.pointsRequester -= 100;
        } else {
          rel.pointsRecipient -= 100;
        }
        await rel.save();
      }
    }
    console.log('Migrated Truth/Dare spendings.');

    // 5. Cleanup User global points (optional but recommended for consistency)
    await User.updateMany({}, { $unset: { points: 1 } });
    console.log('Cleaned up global points from User model.');

    console.log('Migration complete!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();
