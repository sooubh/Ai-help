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
exports.generateDailyPlan = exports.chatWithAI = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const generative_ai_1 = require("@google/generative-ai");
const db = admin.firestore();
// Initialize Gemini using an environment variable or Firebase Secret Manager.
// For local testing, ensure GEMINI_API_KEY is in your functions/.env file.
const getGeminiClient = () => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new functions.https.HttpsError("failed-precondition", "GEMINI_API_KEY is not configured on the server.");
    }
    return new generative_ai_1.GoogleGenerativeAI(apiKey);
};
exports.chatWithAI = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "You must be logged in to chat with the AI.");
    }
    const { prompt } = data;
    if (!prompt || typeof prompt !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "A valid 'prompt' string must be provided.");
    }
    try {
        const genAI = getGeminiClient();
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        // Enforce the system prompt on the backend for security/consistency
        const systemInstruction = "You are a helpful, empathetic, and knowledgeable assistant for parents of children with physical or developmental disabilities. Keep answers brief, supportive, and practical.";
        const enhancedPrompt = systemInstruction + '\n\nUser: ' + prompt;
        const result = await model.generateContent(enhancedPrompt);
        const responseText = result.response.text();
        return { success: true, response: responseText };
    }
    catch (error) {
        functions.logger.error("AI Chat Error", error);
        throw new functions.https.HttpsError("internal", "Failed to generate AI response.");
    }
});
exports.generateDailyPlan = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    }
    const { childId } = data;
    if (!childId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing childId.");
    }
    const uid = context.auth.uid;
    try {
        // 1. Securely fetch the child profile from Firestore
        const childDoc = await db.collection("users").doc(uid).collection("children").doc(childId).get();
        if (!childDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Child profile not found.");
        }
        const { name, age } = childDoc.data();
        const conditions = (_a = childDoc.data()) === null || _a === void 0 ? void 0 : _a.conditions;
        // 2. Query Gemini
        const genAI = getGeminiClient();
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        let knownStr = 'None specified';
        if (conditions && Array.isArray(conditions)) {
            knownStr = conditions.join(", ");
        }
        // Using primitive strings to avoid TS parser complaining about templating missing usages in chunks
        let promptChunks = [];
        promptChunks.push("Create a daily therapy/activity plan for " + name + ", age " + age + ".");
        promptChunks.push("Known conditions: " + knownStr + ".");
        promptChunks.push("Output a JSON array of activities. Each object should have:");
        promptChunks.push("- title: string");
        promptChunks.push("- time: string (e.g., '9:00 AM')");
        promptChunks.push("- duration: number (minutes)");
        promptChunks.push("- status: 'pending'");
        const prompt = promptChunks.join('\n');
        const result = await model.generateContent(prompt);
        // Parse JSON safely
        let planData;
        let rawStr = result.response.text();
        let cleanStr = rawStr;
        if (rawStr.includes('```json')) {
            let arr = rawStr.split('```json');
            if (arr.length > 1) {
                let arr2 = arr[1].split('```');
                cleanStr = arr2[0];
            }
        }
        try {
            planData = JSON.parse(cleanStr);
        }
        catch (_b) {
            planData = [];
        }
        return { success: true, plan: planData };
    }
    catch (error) {
        functions.logger.error("Generate Plan Error", error);
        throw new functions.https.HttpsError("internal", "Failed to generate plan.");
    }
});
//# sourceMappingURL=ai.js.map