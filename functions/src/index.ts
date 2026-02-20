import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { genkit, z } from "genkit";
import { googleAI, gemini15Flash } from "@genkit-ai/googleai";

admin.initializeApp();

// 1. Initialize the Genkit instance using the new syntax
const ai = genkit({
	plugins: [googleAI()],
});

// 2. Define the schema (using Genkit's bundled Zod)
const OutfitSuggestionSchema = z.object({
	title: z.string(),
	clothingIds: z.array(z.string()),
	reasoning: z.string(),
});

// 3. Define the flow attached to the 'ai' instance
export const suggestOutfitsFlow = ai.defineFlow(
	{
		name: "suggestOutfitsFlow",
		inputSchema: z.object({ userId: z.string() }),
		outputSchema: OutfitSuggestionSchema,
	},
	async ({ userId }) => {
		const wardrobeSnapshot = await admin.firestore()
			.collection("users").doc(userId).collection("clothes").get();

		if (wardrobeSnapshot.empty) {
			throw new Error("Wardrobe is empty");
		}

		const wardrobeList = wardrobeSnapshot.docs.map((doc) => {
			const data = doc.data();
			const tags = data.tags?.join(",") || "none";
			return `ID: ${doc.id} | Type: ${data.type} | Color: ${data.color} | Tags: ${tags}`;
		}).join("\n");

		const promptText = "You are an expert fashion stylist. Review this " +
			"wardrobe:\n\n" + wardrobeList + "\n\nCreate exactly ONE stylish " +
			"outfit combination. Ensure colors match. You MUST return the exact " +
			"'ID' strings of the items you select. Give the outfit a title " +
			"and explain why it works.";

		// 4. Call generate on the 'ai' instance
		const response = await ai.generate({
			model: gemini15Flash,
			prompt: promptText,
			output: { schema: OutfitSuggestionSchema },
		});

		if (!response.output) {
			throw new Error("Failed to generate an outfit from AI.");
		}

		return response.output;
	}
);

// 5. Use Firebase Functions V2 syntax (request.auth instead of context.auth)
export const generateOutfitSuggestion = onCall(
	async (request) => {
		// Check if the user is authenticated
		if (!request.auth) {
			throw new HttpsError(
				"unauthenticated",
				"User must be logged in."
			);
		}

		try {
			// In the new Genkit, flows can be called directly as async functions
			const suggestion = await suggestOutfitsFlow({
				userId: request.auth.uid,
			});
			return suggestion;
		} catch (error) {
			console.error("Error generating outfit:", error);
			throw new HttpsError(
				"internal",
				"Failed to generate outfit."
			);
		}
	}
);