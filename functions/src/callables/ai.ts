import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

const db = admin.firestore();

// Initialize Gemini using an environment variable or Firebase Secret Manager.
// For local testing, ensure GEMINI_API_KEY is in your functions/.env file.
const getGeminiClient = () => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "GEMINI_API_KEY is not configured on the server."
        );
    }
    return new GoogleGenerativeAI(apiKey);
};

export const chatWithAI = functions.https.onCall(async (data, context) => {
    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to chat with the AI."
        );
    }

    const { prompt } = data;
    if (!prompt || typeof prompt !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "A valid 'prompt' string must be provided."
        );
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
    } catch (error) {
        functions.logger.error("AI Chat Error", error);
        throw new functions.https.HttpsError("internal", "Failed to generate AI response.");
    }
});

export const generateDailyPlan = functions.https.onCall(async (data, context) => {
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

        const { name, age } = childDoc.data()!;
        const conditions = childDoc.data()?.conditions;

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
        } catch {
            planData = [];
        }

        return { success: true, plan: planData };
    } catch (error) {
        functions.logger.error("Generate Plan Error", error);
        throw new functions.https.HttpsError("internal", "Failed to generate plan.");
    }
});
