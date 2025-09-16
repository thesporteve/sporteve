import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import OpenAI from "openai";

admin.initializeApp();
const db = admin.firestore();

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

// Log if API key is loaded (don't log the actual key for security)
console.log("OpenAI API key loaded:",
  functions.config().openai.key ? "Yes" : "No");

export const processNewsStaging = functions.firestore
  .document("news_staging/{docId}")
  .onCreate(async (
    snap: functions.firestore.QueryDocumentSnapshot,
    context: functions.EventContext
  ) => {
    const data = snap.data();
    if (!data || !data.title || !data.summary) {
      console.log("Invalid data, skipping. Missing:", {
        title: !data.title,
        summary: !data.summary,
      });
      return;
    }

    const prompt = `
      Curate this sports news article for better mobile UI display:
      
      Title: ${data.title}
      Summary: ${data.summary}
      
      Please provide:
      1. A compelling, SEO-friendly title (50 characters or less)
      2. A concise description that hooks readers (max 120 chars, 2 lines)
      
      The description should:
      - Be punchy and engaging
      - Fit in exactly 2 lines on mobile
      - End with proper punctuation
      - Avoid unnecessary words
      
      Format your response as:
      TITLE: [your curated title]
      DESCRIPTION: [your curated description]
    `;

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [{role: "user", content: prompt}],
        temperature: 0.7,
        max_tokens: 300,
      });

      const curatedText = response.choices[0].message?.content ?? "";

      // Parse the response to extract title and description
      const titleMatch = curatedText.match(
        /TITLE:\s*(.+?)(?=\n|DESCRIPTION:|$)/i
      );
      const descriptionMatch = curatedText.match(
        /DESCRIPTION:\s*(.+?)$/i
      );

      const curatedTitle = titleMatch?.[1]?.trim() || data.title;
      let curatedDescription = descriptionMatch?.[1]?.trim() ||
        data.summary;

      // Ensure description fits in mobile UI (max 120 characters)
      if (curatedDescription.length > 120) {
        curatedDescription = curatedDescription.substring(0, 117) + "...";
      }

      // Preserve all original fields and add curated content plus publication
      const publishedArticle: Record<string, unknown> = {
        ...data, // Preserve all original fields
        title: curatedTitle,
        description: curatedDescription,
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        curated_at: admin.firestore.FieldValue.serverTimestamp(),
        status: "published",
        original_title: data.title, // Keep original for reference
        original_summary: data.summary, // Keep original for reference
      };

      // Remove staging-specific fields
      delete publishedArticle.submitted_at;

      await db.collection("news_articles").doc(context.params.docId)
        .set(publishedArticle);

      console.log("Article curated and published successfully:",
        context.params.docId);
    } catch (err: unknown) {
      console.error("Error curating article:", err);

      // If curation fails, publish original content anyway
      const errorMessage = err instanceof Error ? err.message :
        "Unknown error occurred";

      // Truncate original summary if too long
      let fallbackDescription = data.summary;
      if (fallbackDescription && fallbackDescription.length > 120) {
        fallbackDescription = fallbackDescription.substring(0, 117) + "...";
      }

      const fallbackArticle: Record<string, unknown> = {
        ...data,
        // Use truncated summary as description
        description: fallbackDescription,
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "published",
        curation_failed: true,
        error_message: errorMessage,
      };

      delete fallbackArticle.submitted_at;

      await db.collection("news_articles").doc(context.params.docId)
        .set(fallbackArticle);
      console.log("Published original article due to curation failure:",
        context.params.docId);
    }
  });
