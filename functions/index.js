const admin = require("firebase-admin");
const functions = require("firebase-functions"); // ✅ Import functions properly
const { onCall } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

// ✅ Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = getFirestore();
const auth = getAuth();
const storage = getStorage().bucket();

// ✅ Function to delete subcollections safely (skips empty ones)
async function deleteSubcollections(userId) {
  console.log(`🔍 Checking subcollections for user: ${userId}`);
  const subcollections = ["readings", "grids"];

  for (const sub of subcollections) {
    const collectionRef = db.collection(`users/${userId}/${sub}`);
    const snapshot = await collectionRef.get();

    if (snapshot.empty) {
      console.log(`⚠️ No documents found in ${sub}, skipping...`);
      continue; // ✅ Skip to the next collection
    }

    console.log(`🔄 Deleting ${snapshot.size} documents from ${sub}...`);
    const batch = db.batch();
    snapshot.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    console.log(`✅ Deleted all documents from ${sub}`);
  }
}

// ✅ Main Function to Delete User Account
exports.deleteUserAccount = onCall(async (data, context) => {
  console.log("🛑 deleteUserAccount function triggered.");

  if (!data.token) {
    console.error("❌ Missing authentication token.");
    throw new functions.https.HttpsError("unauthenticated", "Missing token.");
  }

  let userId;
  try {
    console.log("🔍 Verifying token...");
    const decodedToken = await auth.verifyIdToken(data.token);
    userId = decodedToken.uid;
    console.log(`✅ Token valid. User ID: ${userId}`);
  } catch (error) {
    console.error("❌ Invalid authentication token:", error);
    throw new functions.https.HttpsError("unauthenticated", "Invalid token.");
  }

  console.log(`🔄 Starting account deletion for UID: ${userId}`);

  try {
    // ✅ Check if user exists before deleting
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.warn(`⚠️ User ${userId} already deleted.`);
      return { success: true, message: "User already deleted." };
    }

    // ✅ Delete subcollections safely (handles empty collections)
    console.time("🕒 Firestore subcollections deleted");
    await deleteSubcollections(userId);
    console.timeEnd("🕒 Firestore subcollections deleted");

    // ✅ Delete Firestore User Document
    console.time("🕒 Firestore user document deleted");
    await db.collection("users").doc(userId).delete();
    console.timeEnd("🕒 Firestore user document deleted");

    // ✅ Delete Firebase Storage Files
    console.time("🕒 Firebase Storage files deleted");
    try {
      const [files] = await storage.getFiles({ prefix: `users/${userId}/` });
      if (files.length > 0) {
        await Promise.all(files.map((file) => file.delete()));
        console.log(`✅ Deleted ${files.length} files from storage.`);
      } else {
        console.warn("⚠️ No files found to delete.");
      }
    } catch (storageError) {
      console.warn("⚠️ Error deleting storage files:", storageError);
    }
    console.timeEnd("🕒 Firebase Storage files deleted");

    // ✅ Delete Firebase Authentication User
    console.time("🕒 Firebase Authentication user deleted");
    await auth.deleteUser(userId);
    console.timeEnd("🕒 Firebase Authentication user deleted");

    console.log("✅ Account deletion completed.");
    return { success: true, message: "User account deleted successfully." };

  } catch (error) {
    console.error("❌ Error during user deletion:", error);
    throw new functions.https.HttpsError("internal", `Failed to delete user: ${error.message}`);
  }
});
