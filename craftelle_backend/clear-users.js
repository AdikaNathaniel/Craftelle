const { MongoClient } = require('mongodb');

// Get MongoDB URI from command line argument or use default
const MONGODB_URI = process.argv[2] || process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ Error: MongoDB URI is required!');
  console.log('\nUsage:');
  console.log('  node clear-users.js "your-mongodb-uri"');
  console.log('  or set MONGODB_URI environment variable');
  process.exit(1);
}

async function clearUsers() {
  let client;

  try {
    console.log('🔌 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();

    console.log('✅ Connected to MongoDB successfully!');

    const db = client.db();
    const usersCollection = db.collection('users');

    // Count users before deletion
    const countBefore = await usersCollection.countDocuments();
    console.log(`📊 Found ${countBefore} users in the database`);

    if (countBefore === 0) {
      console.log('ℹ️  Database is already empty. No users to delete.');
      return;
    }

    // Delete all users
    console.log('🗑️  Deleting all users...');
    const result = await usersCollection.deleteMany({});

    console.log(`✅ Successfully deleted ${result.deletedCount} users`);

    // Verify deletion
    const countAfter = await usersCollection.countDocuments();
    console.log(`📊 Users remaining: ${countAfter}`);

    if (countAfter === 0) {
      console.log('🎉 Database is now empty! You can register a new account.');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.message.includes('ENOTFOUND') || error.message.includes('connection')) {
      console.error('\nConnection failed. Please check:');
      console.error('  1. Your MongoDB URI is correct');
      console.error('  2. Your network connection');
      console.error('  3. MongoDB server is running');
    }
    process.exit(1);
  } finally {
    if (client) {
      await client.close();
      console.log('🔌 Disconnected from MongoDB');
    }
  }
}

// Run the script
clearUsers();
