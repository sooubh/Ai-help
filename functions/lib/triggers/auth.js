"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDeleted = exports.onUserCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;
    // Initialize the master user document when they sign up
    await db.collection("users").doc(uid).set({
        email: email || "",
        displayName: displayName || "",
        photoUrl: photoURL || "",
        role: "parent",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info(`Initialized Firestore document for new user: \${uid}`);
});
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
    const uid = user.uid;
    // Define collections to cascade delete for this user
    const userDocRef = db.collection("users").doc(uid);
    // Note: For a true cascade delete in Firestore on large subcollections, 
    // you'd typically query and delete batches. This is a simplified recursive delete 
    // utilizing the firebase-admin library built-in recursive delete (Node 16+ env recommended).
    try {
        await db.recursiveDelete(userDocRef);
        functions.logger.info(`Successfully cascade-deleted data for user: \${uid}`);
    }
    catch (error) {
        functions.logger.error(`Failed to delete data for user: \${uid}`, error);
    }
});
//# sourceMappingURL=auth.js.map