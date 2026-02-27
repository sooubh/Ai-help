import * as admin from "firebase-admin";

// Initialize Firebase Admin globally
admin.initializeApp();

// Export all triggers
export * from "./triggers/auth";

// Export all callables
export * from "./callables/ai";
