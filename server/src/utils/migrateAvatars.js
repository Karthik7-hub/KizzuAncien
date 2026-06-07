const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config({ path: '../../.env' });

const migrate = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB for migration...');

    const users = await User.find({
      $or: [
        { gender: { $exists: false } },
        { avatarType: { $exists: false } }
      ]
    });

    console.log(`Found ${users.length} users to migrate.`);

    for (const user of users) {
      if (!user.gender) user.gender = 'male';
      if (!user.avatarType) {
        user.avatarType = user.gender === 'male' ? 'male_default' : 'female_default';
      }
      // Clear old generated URLs if they were stored in profileImageUrl

      await user.save();
      console.log(`Migrated user: ${user.username}`);
    }

    console.log('Migration completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
};

migrate();
