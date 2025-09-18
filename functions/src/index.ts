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
    if (!data || !data.title || !data.summary || !data.content) {
      console.log("Invalid data, skipping. Missing:", {
        title: !data.title,
        summary: !data.summary,
        content: !data.content,
      });
      return;
    }

    const prompt = `
    Curate this sports news article for better mobile UI display:
    
    Title: ${data.title}
    Description (for cards): ${data.summary}
    Summary (for detail page): ${data.content}
    
    Please provide:
    1. A compelling, SEO-friendly title (50 characters or less)
    2. A concise description that hooks readers (max 120 chars, 2 lines)
    3. An engaging summary for the detail page (max 300 chars)
    
    The description should be punchy and engaging for news cards.
    The summary should be informative but concise for the detail page.
    Both should end with proper punctuation and avoid unnecessary words.
    
    Format your response as:
    TITLE: [your curated title]
    DESCRIPTION: [your curated description]
    SUMMARY: [your curated summary]
  `;

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [{role: "user", content: prompt}],
        temperature: 0.7,
        max_tokens: 500, // Increased for 3 fields instead of 2
      });

      const curatedText = response.choices[0].message?.content ?? "";

      // Parse the response to extract title, description, and summary
      const titleMatch = curatedText.match(
        /TITLE:\s*(.+?)(?=\n|DESCRIPTION:|$)/i
      );
      const descriptionMatch = curatedText.match(
        /DESCRIPTION:\s*(.+?)(?=\n|SUMMARY:|$)/i
      );
      const summaryMatch = curatedText.match(
        /SUMMARY:\s*([\s\S]*?)$/i
      );

      const curatedTitle = titleMatch?.[1]?.trim() || data.title;
      let curatedDescription = descriptionMatch?.[1]?.trim() || data.summary;
      let curatedSummary = summaryMatch?.[1]?.trim() || data.content;

      // Ensure description fits in mobile UI (max 120 characters)
      if (curatedDescription.length > 120) {
        curatedDescription = curatedDescription.substring(0, 117) + "...";
      }

      // Ensure summary fits in mobile UI (max 300 characters)
      if (curatedSummary.length > 300) {
        curatedSummary = curatedSummary.substring(0, 297) + "...";
      }

      // Preserve all original fields and add curated content plus publication
      const publishedArticle: Record<string, unknown> = {
        ...data, // Preserve all original fields
        title: curatedTitle,
        description: curatedDescription, // Curated from original summary
        summary: curatedSummary, // Curated from original content
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        curated_at: admin.firestore.FieldValue.serverTimestamp(),
        status: "published",
        original_title: data.title, // Keep original for reference
        original_summary: data.summary, // Keep original summary (description)
        original_content: data.content, // Keep original content (summary)
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

      // Truncate original fields if too long for mobile UI
      let fallbackDescription = data.summary;
      if (fallbackDescription && fallbackDescription.length > 120) {
        fallbackDescription = fallbackDescription.substring(0, 117) + "...";
      }

      let fallbackSummary = data.content;
      if (fallbackSummary && fallbackSummary.length > 300) {
        fallbackSummary = fallbackSummary.substring(0, 297) + "...";
      }

      const fallbackArticle: Record<string, unknown> = {
        ...data,
        // Use original fields but truncated for mobile
        description: fallbackDescription, // From original summary
        summary: fallbackSummary, // From original content
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

/**
 * Push notification trigger when article is added to news_articles
 */
export const sendArticleNotification = functions.firestore
  .document("news_articles/{docId}")
  .onCreate(async (
    snap: functions.firestore.QueryDocumentSnapshot,
    context: functions.EventContext
  ) => {
    const data = snap.data();

    if (!data || !data.title || !data.description || !data.category) {
      console.log("Invalid article data for notification, skipping:", {
        title: !data.title,
        description: !data.description,
        category: !data.category,
      });
      return;
    }

    try {
      // Determine topics to send to
      const topics = [];

      // Always send to general sports news
      topics.push("sports_news");

      // Send to specific sport category
      topics.push(`sport_${data.category.toLowerCase()}`);

      console.log(`📱 Sending notifications to topics: ${topics} ` +
        `for article: ${data.title}`);

      // Send notification to each topic
      for (const topic of topics) {
        try {
          const message = {
            topic: topic,
            notification: {
              title: formatNotificationTitle(data.title, data.category),
              body: formatNotificationBody(data.description),
            },
            data: {
              article_id: context.params.docId,
              category: data.category,
              screen: "news_detail",
              timestamp: Date.now().toString(),
            },
            android: {
              priority: "high" as const,
            },
            apns: {
              headers: {
                "apns-priority": "10",
              },
            },
          };

          await admin.messaging().send(message);
          console.log(`✅ Notification sent to topic "${topic}" ` +
            `for article: ${data.title}`);

          // Log to Firestore for tracking
          await db.collection("notifications").add({
            topic: topic,
            title: message.notification.title,
            body: message.notification.body,
            data: message.data,
            article_id: context.params.docId,
            sent_at: admin.firestore.FieldValue.serverTimestamp(),
            sent: true,
          });
        } catch (topicError: unknown) {
          console.error("❌ Failed to send notification to " +
            `topic "${topic}":`, topicError);

          const errorMessage = topicError instanceof Error ?
            topicError.message : "Unknown error occurred";

          // Log failed notification to Firestore
          await db.collection("notifications").add({
            topic: topic,
            title: formatNotificationTitle(data.title, data.category),
            body: formatNotificationBody(data.description),
            data: {
              article_id: context.params.docId,
              category: data.category,
              screen: "news_detail",
              timestamp: Date.now().toString(),
            },
            article_id: context.params.docId,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            sent: false,
            error: errorMessage,
          });
        }
      }
    } catch (error) {
      console.error("❌ Error sending article notification:", error);
    }
  });

/**
 * Format notification title based on article type
 * @param {string} title Article title
 * @param {string} category Article category
 * @return {string} Formatted title
 */
function formatNotificationTitle(title: string, category: string): string {
  const sportName = getCategoryDisplayName(category);
  return `⚽ ${sportName}: ${truncateText(title, 45)}`;
}

/**
 * Format notification body
 * @param {string} description Article description
 * @return {string} Formatted body
 */
function formatNotificationBody(description: string): string {
  return truncateText(description, 100);
}

/**
 * Get display name for sport category
 * @param {string} category Category string
 * @return {string} Display name
 */
function getCategoryDisplayName(category: string): string {
  switch (category.toLowerCase()) {
  case "football":
    return "Football";
  case "soccer":
    return "Soccer";
  case "basketball":
    return "Basketball";
  case "cricket":
    return "Cricket";
  case "tennis":
    return "Tennis";
  case "baseball":
    return "Baseball";
  case "hockey":
    return "Hockey";
  case "volleyball":
    return "Volleyball";
  case "rugby":
    return "Rugby";
  case "golf":
    return "Golf";
  case "athletics":
    return "Athletics";
  case "swimming":
    return "Swimming";
  case "boxing":
    return "Boxing";
  case "wrestling":
    return "Wrestling";
  case "weightlifting":
    return "Weightlifting";
  default:
    return category.split("_")
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(" ");
  }
}

/**
 * Truncate text to specified length
 * @param {string} text Text to truncate
 * @param {number} maxLength Maximum length
 * @return {string} Truncated text
 */
function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return `${text.substring(0, maxLength - 3)}...`;
}
