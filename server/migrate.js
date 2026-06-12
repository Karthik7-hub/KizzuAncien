const mongoose = require('mongoose');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

dotenv.config();

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error('MONGO_URI not found in .env');
  process.exit(1);
}

// Minimal models for migration
const ChallengeSchema = new mongoose.Schema({
  proofType: String,
  unreadCount: { type: Map, of: Number }
}, { strict: false });

const Challenge = mongoose.model('Challenge', ChallengeSchema);

const ChallengeSubmissionSchema = new mongoose.Schema({
  challenge: mongoose.Schema.Types.ObjectId,
  submitter: mongoose.Schema.Types.ObjectId,
  proofUrl: String,
  proofText: String,
  proofType: String,
  status: String,
  versions: Array,
  currentVersion: Number,
  versionCount: Number,
  latestVersionData: Object
}, { strict: false });

const ChallengeSubmission = mongoose.model('ChallengeSubmission', ChallengeSubmissionSchema);

async function backupData(db) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = path.join(__dirname, 'backups');
  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);

  const collections = await db.db.listCollections().toArray();
  const report = {};

  for (const col of collections) {
    const data = await db.db.collection(col.name).find({}).toArray();
    const filePath = path.join(backupDir, `${col.name}_${timestamp}.json`);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    report[col.name] = data.length;
  }
  return { timestamp, report };
}

function analyzeVideoContent(proofUrl, proofText) {
  if (!proofUrl) {
    return { type: 'explanation', content: proofText || 'No content provided' };
  }

  const extension = path.extname(proofUrl).toLowerCase();
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

  if (imageExtensions.includes(extension) || proofUrl.includes('imagekit.io')) {
    return { type: 'image', content: proofUrl };
  }

  // If it's a URL but not clearly an image, treat as link
  if (proofUrl.startsWith('http')) {
    return { type: 'link', content: proofUrl };
  }

  return { type: 'explanation', content: proofText || proofUrl || 'Legacy video content' };
}

async function migrate() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('Connected.');

    console.log('Backing up data...');
    const backup = await backupData(mongoose.connection);
    console.log('Backup complete:', backup.report);

    const migrationReport = {
      challengesUpdated: 0,
      submissionsMigrated: 0,
      notesConverted: {
        image: 0,
        explanation: 0,
        link: 0,
        code: 0
      },
      skipped: 0,
      manualReview: 0
    };

    // 1. Update Challenges
    console.log('Migrating Challenges...');
    const challenges = await Challenge.find({});
    for (const challenge of challenges) {
      let updated = false;

      // Initialize unreadCount if missing
      if (!challenge.unreadCount) {
        challenge.unreadCount = {};
        updated = true;
      }

      // Remove legacy 'video' proofType if it's there
      if (challenge.proofType === 'video') {
        challenge.proofType = 'any';
        updated = true;
      }

      if (updated) {
        await challenge.save();
        migrationReport.challengesUpdated++;
      }
    }

    // 2. Migrate Submissions
    console.log('Migrating Submissions...');
    const submissions = await ChallengeSubmission.find({});
    for (const sub of submissions) {
      // Check if already migrated (has versions)
      if (sub.versions && sub.versions.length > 0) {
        migrationReport.skipped++;
        continue;
      }

      const notes = [];
      let conversionCase = '';

      if (sub.proofType === 'text') {
        notes.push({
          type: 'explanation',
          content: sub.proofText || 'Legacy submission text',
          version: 1,
          createdAt: sub.createdAt,
          updatedAt: sub.updatedAt
        });
        migrationReport.notesConverted.explanation++;
        conversionCase = 'Text to Explanation';
      } else if (sub.proofType === 'image') {
        notes.push({
          type: 'image',
          content: sub.proofUrl,
          version: 1,
          createdAt: sub.createdAt,
          updatedAt: sub.updatedAt
        });
        migrationReport.notesConverted.image++;
        conversionCase = 'Image to Image';
      } else if (sub.proofType === 'video') {
        const converted = analyzeVideoContent(sub.proofUrl, sub.proofText);
        notes.push({
          ...converted,
          version: 1,
          createdAt: sub.createdAt,
          updatedAt: sub.updatedAt
        });
        migrationReport.notesConverted[converted.type]++;
        conversionCase = `Video to ${converted.type}`;
      } else {
        // Fallback for any other type
        notes.push({
          type: 'explanation',
          content: sub.proofText || sub.proofUrl || 'Legacy submission',
          version: 1,
          createdAt: sub.createdAt,
          updatedAt: sub.updatedAt
        });
        migrationReport.notesConverted.explanation++;
        conversionCase = 'Fallback to Explanation';
      }

      const firstVersion = {
        versionNumber: 1,
        notes: notes,
        status: sub.status || 'pending',
        createdBy: sub.submitter,
        createdAt: sub.createdAt,
        updatedAt: sub.updatedAt
      };

      sub.versions = [firstVersion];
      sub.currentVersion = 1;
      sub.versionCount = 1;
      sub.latestVersionData = {
        versionNumber: 1,
        noteCount: notes.length,
        types: notes.map(n => n.type),
        status: firstVersion.status
      };

      // Clean up legacy fields (optional, but keep for safety if required by user)
      // sub.proofUrl = undefined;
      // sub.proofText = undefined;
      // sub.proofType = undefined;

      await sub.save();
      migrationReport.submissionsMigrated++;
    }

    console.log('\nMigration Complete!');
    console.log('-------------------');
    console.log(JSON.stringify(migrationReport, null, 2));

    const reportPath = path.join(__dirname, `migration_report_${new Date().getTime()}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(migrationReport, null, 2));
    console.log(`\nReport saved to: ${reportPath}`);

    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();
