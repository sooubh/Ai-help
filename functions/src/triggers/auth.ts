import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;

    // Initialize the master user document when they sign up
    await db.collection("users").doc(uid).set({
        email: email || "",
        displayName: displayName || "",
        photoUrl: photoURL || "",
        role: "parent", // Default role
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Initialized Firestore document for new user: \${uid}`);
});

export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
    const uid = user.uid;

    // Define collections to cascade delete for this user
    const userDocRef = db.collection("users").doc(uid);

    // Note: For a true cascade delete in Firestore on large subcollections, 
    // you'd typically query and delete batches. This is a simplified recursive delete 
    // utilizing the firebase-admin library built-in recursive delete (Node 16+ env recommended).

    try {
        await db.recursiveDelete(userDocRef);
        functions.logger.info(`Successfully cascade-deleted data for user: \${uid}`);
    } catch (error) {
        functions.logger.error(`Failed to delete data for user: \${uid}`, error);
    }
});
