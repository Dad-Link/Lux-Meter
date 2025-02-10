const admin = require("firebase-admin");

// ✅ Load Service Account Key
const serviceAccount = require("./serviceAccountKey.json");

// ✅ Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const auth = admin.auth();

async function deleteUser(userId) {
  try {
    await auth.deleteUser(userId);
    console.log(`✅ Successfully deleted user: ${userId}`);
  } catch (error) {
    console.error("❌ Error deleting user:", error);
  }
}

// ✅ Change user ID here to test
const userId = "A1VGLxoPN4Ppv7yjdxWLnlIYqKw1";
deleteUser(userId);
