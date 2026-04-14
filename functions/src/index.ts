import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { genkit, z } from "genkit";
import { googleAI, gemini15Flash } from "@genkit-ai/googleai";

admin.initializeApp();

const googleAiApiKey = defineSecret("GOOGLE_GENAI_API_KEY");

const OutfitSuggestionSchema = z.object({
	title: z.string(),
	clothingIds: z.array(z.string()),
	reasoning: z.string(),
});

export const generateOutfitSuggestion = onCall(
	{ secrets: [googleAiApiKey] },
	async (request) => {
		if (!request.auth) {
			throw new HttpsError("unauthenticated", "User must be logged in.");
		}

		const userId = request.auth.uid;

		const wardrobeSnapshot = await admin.firestore()
			.collection("users").doc(userId).collection("clothes").get();

		if (wardrobeSnapshot.empty) {
			throw new HttpsError("failed-precondition", "Your wardrobe is empty. Add some clothes first.");
		}

		const wardrobeList = wardrobeSnapshot.docs.map((doc) => {
			const data = doc.data();
			const tags = (data.tags as string[] | undefined)?.join(", ") || "none";
			return `ID: ${doc.id} | Type: ${data.type} | Color: ${data.color} | Tags: ${tags}`;
		}).join("\n");

		const promptText =
			"You are an expert fashion stylist. Review this wardrobe:\n\n" +
			wardrobeList +
			"\n\nCreate exactly ONE stylish outfit. Colors must coordinate well. " +
			"You MUST use the exact 'ID' strings from the list above in clothingIds. " +
			"Give the outfit a short title and explain why the combination works.";

		const ai = genkit({
			plugins: [googleAI({ apiKey: googleAiApiKey.value() })],
		});

		try {
			const response = await ai.generate({
				model: gemini15Flash,
				prompt: promptText,
				output: { schema: OutfitSuggestionSchema },
			});

			if (!response.output) {
				throw new HttpsError("internal", "AI did not return a valid outfit.");
			}

			return response.output;
		} catch (error) {
			console.error("Genkit error:", error);
			throw new HttpsError("internal", "Failed to generate outfit suggestion.");
		}
	}
);
