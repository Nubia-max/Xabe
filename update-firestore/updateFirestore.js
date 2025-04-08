const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Path to your service account key

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Function to update all posts with the taggedUsers field
async function updatePosts() {
  try {
    // Get all posts from the "posts" collection
    const postsRef = db.collection('posts');
    const snapshot = await postsRef.get();

    // Iterate through each post
    snapshot.forEach(async (doc) => {
      const postData = doc.data();

      // Check if the post already has the taggedUsers field
      if (!postData.taggedUsers) {
        // Add the taggedUsers field with an empty list (or default value)
        await doc.ref.update({
          taggedUsers: [], // Default value (empty list)
        });

        console.log(`Updated post ${doc.id} with taggedUsers field.`);
      } else {
        console.log(`Post ${doc.id} already has the taggedUsers field.`);
      }
    });

    console.log('All posts have been updated.');
  } catch (error) {
    console.error('Error updating posts:', error);
  }
}

// Run the update function
updatePosts();