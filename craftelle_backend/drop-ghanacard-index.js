const { MongoClient } = require('mongodb');

// Get MongoDB URI from command line argument or environment variable
const MONGODB_URI = process.argv[2] || process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ Error: MongoDB URI is required!');
  console.log('\nUsage:');
  console.log('  node drop-ghanacard-index.js "your-mongodb-uri"');
  console.log('  or set MONGODB_URI environment variable');
  process.exit(1);
}

async function dropGhanaCardIndex() {
  let client;

  try {
    console.log('🔌 Connecting to MongoDB...');
    client = new MongoClient(MONGODB_URI);
    await client.connect();

    console.log('✅ Connected to MongoDB successfully!');

    const db = client.db();
    const usersCollection = db.collection('users');

    // List all indexes
    console.log('📋 Listing all indexes on users collection...');
    const indexes = await usersCollection.indexes();
    console.log('Current indexes:', JSON.stringify(indexes, null, 2));

    // Check if GhanaCard index exists
    const ghanaCardIndex = indexes.find(idx =>
      idx.name === 'GhanaCard_1' ||
      idx.name === 'card_1' ||
      (idx.key && (idx.key.GhanaCard || idx.key.card))
    );

    if (ghanaCardIndex) {
      console.log(`🗑️  Found GhanaCard index: ${ghanaCardIndex.name}`);
      console.log('Dropping index...');

      await usersCollection.dropIndex(ghanaCardIndex.name);
      console.log(`✅ Successfully dropped index: ${ghanaCardIndex.name}`);
    } else {
      console.log('ℹ️  No GhanaCard or card index found.');
    }

    // List indexes after dropping
    console.log('\n📋 Indexes after cleanup:');
    const remainingIndexes = await usersCollection.indexes();
    console.log(JSON.stringify(remainingIndexes, null, 2));

    console.log('\n🎉 Done! You can now register users without the duplicate key error.');

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
dropGhanaCardIndex();
