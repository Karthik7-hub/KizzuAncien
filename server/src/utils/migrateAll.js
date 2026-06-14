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
    const mongoUri = process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MONGO_URI is not defined in .env');
    }

    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB successfully.');

    // ----------------------------------------------------
    // STEP 1: Migrate User Avatars
    // ----------------------------------------------------
    console.log('\n--- Step 1: Migrating User Avatars ---');
    const usersToMigrateAvatars = await User.find({
      $or: [
        { gender: { $exists: false } },
        { avatarType: { $exists: false } }
      ]
    });

    console.log(`Found ${usersToMigrateAvatars.length} users needing avatar migration.`);
    for (const user of usersToMigrateAvatars) {
      if (!user.gender) user.gender = 'male';
      if (!user.avatarType) {
        user.avatarType = user.gender === 'male' ? 'male_default' : 'female_default';
      }
      await user.save();
      console.log(`Migrated avatars for user: ${user.username || user.email}`);
    }

    // ----------------------------------------------------
    // STEP 2: Migrate User Preferences
    // ----------------------------------------------------
    console.log('\n--- Step 2: Migrating User Preferences ---');
    const usersToMigratePreferences = await User.find({
      preferences: { $exists: false }
    });

    console.log(`Found ${usersToMigratePreferences.length} users needing preferences migration.`);
    const defaultPreferences = {
      notifications: {
        challenges: true,
        friendRequests: true,
        approvals: true,
        streaks: true
      },
      privacy: {
        allowFriendRequests: true,
        allowChallengeRequests: true,
        profileVisibility: 'friends'
      },
      appearance: {
        theme: 'dark'
      }
    };

    for (const user of usersToMigratePreferences) {
      user.preferences = defaultPreferences;
      await user.save();
      console.log(`Initialized default preferences for user: ${user.username || user.email}`);
    }

    // ----------------------------------------------------
    // STEP 3: Migrate Relationship Points
    // ----------------------------------------------------
    console.log('\n--- Step 3: Migrating Relationship Points ---');
    
    // Reset all relationship points to 0 first
    const resetResult = await Friend.updateMany({}, { pointsRequester: 0, pointsRecipient: 0 });
    console.log(`Reset relationship points for all Friend relationships (${resetResult.modifiedCount} modified).`);

    // Migrate Challenge Rewards (5 points per approved challenge)
    const approvedChallenges = await Challenge.find({ status: 'approved' });
    console.log(`Found ${approvedChallenges.length} approved challenges.`);

    let challengesMigratedCount = 0;
    for (const challenge of approvedChallenges) {
      const rel = await Friend.findOne({
        $or: [
          { requester: challenge.creator, recipient: challenge.recipient },
          { requester: challenge.recipient, recipient: challenge.creator }
        ],
        status: 'accepted'
      });

      if (rel) {
        if (rel.requester.toString() === challenge.recipient.toString()) {
          rel.pointsRequester += 5;
        } else {
          rel.pointsRecipient += 5;
        }
        await rel.save();
        challengesMigratedCount++;
      }
    }
    console.log(`Migrated rewards for ${challengesMigratedCount} challenges.`);

    // Migrate Truth Spendings (-50 points per Truth sent)
    const truths = await Truth.find({});
    console.log(`Found ${truths.length} Truth records.`);
    let truthsMigratedCount = 0;
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
        truthsMigratedCount++;
      }
    }
    console.log(`Migrated spendings for ${truthsMigratedCount} Truth items.`);

    // Migrate Dare Spendings (-100 points per Dare sent)
    const dares = await Dare.find({});
    console.log(`Found ${dares.length} Dare records.`);
    let daresMigratedCount = 0;
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
        daresMigratedCount++;
      }
    }
    console.log(`Migrated spendings for ${daresMigratedCount} Dare items.`);

    console.log('\nAll migrations completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();
