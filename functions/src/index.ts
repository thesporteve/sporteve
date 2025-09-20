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
/**
 * Push notification trigger when content feed is published
 */
export const sendContentFeedNotification = functions.firestore
  .document("content_feeds/{docId}")
  .onUpdate(async (
    change: functions.Change<functions.firestore.QueryDocumentSnapshot>,
    context: functions.EventContext
  ) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Only trigger if status changed to 'published'
    if (beforeData.status !== "published" && afterData.status === "published") {
      const contentTitle = afterData.content?.question ||
        afterData.content?.title ||
        afterData.content?.fact ||
        "New Content";
      console.log("📱 Content feed published, sending notification: " +
        `${contentTitle}`);
      try {
        // Determine topics based on content type and sport
        const topics = [];

        // Add general content topic
        topics.push("sports_content");

        // Add specific sport category topic
        if (afterData.sport_category) {
          topics.push(`sport_${afterData.sport_category.toLowerCase()}`);
        }

        // Add content type specific topic
        if (afterData.type) {
          // trivia, parent_tip, did_you_know
          topics.push(`content_${afterData.type}`);
        }

        console.log("📱 Sending content notifications to topics: " +
          `${topics.join(", ")}`);

        // Send notification to each topic
        for (const topic of topics) {
          try {
            const message = {
              topic: topic,
              notification: {
                title: formatContentNotificationTitle(afterData),
                body: formatContentNotificationBody(afterData),
              },
              data: {
                content_id: context.params.docId,
                content_type: afterData.type,
                sport_category: afterData.sport_category,
                screen: getContentScreenName(afterData.type),
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
            console.log(`✅ Content notification sent to topic "${topic}"`);

            // Log to Firestore for tracking
            await db.collection("notifications").add({
              topic: topic,
              title: message.notification.title,
              body: message.notification.body,
              data: message.data,
              content_id: context.params.docId,
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              sent: true,
            });
          } catch (topicError: unknown) {
            console.error("❌ Failed to send content notification to " +
              `topic "${topic}":`, topicError);
            const errorMessage = topicError instanceof Error ?
              topicError.message : "Unknown error occurred";

            // Log failed notification to Firestore
            await db.collection("notifications").add({
              topic: topic,
              title: formatContentNotificationTitle(afterData),
              body: formatContentNotificationBody(afterData),
              data: {
                content_id: context.params.docId,
                content_type: afterData.type,
                sport_category: afterData.sport_category,
                screen: getContentScreenName(afterData.type),
                timestamp: Date.now().toString(),
              },
              content_id: context.params.docId,
              created_at: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
              error: errorMessage,
            });
          }
        }
      } catch (error) {
        console.error("❌ Error sending content feed notification:", error);
      }
    }
  });

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
 * Format content feed notification title
 * @param {object} contentData Content feed data
 * @return {string} Formatted title
 */
function formatContentNotificationTitle(
  contentData: {[key: string]: any}
): string {
  const sportName = getCategoryDisplayName(contentData.sport_category || "");
  switch (contentData.type) {
  case "trivia":
    return `🧠 ${sportName} Trivia!`;
  case "parent_tip":
    return `👨‍👩‍👧‍👦 ${sportName} Parent Tip`;
  case "did_you_know":
    return `💡 ${sportName} Fun Fact`;
  default:
    return `⚽ New ${sportName} Content`;
  }
}

/**
 * Format content feed notification body
 * @param {object} contentData Content feed data
 * @return {string} Formatted body
 */
function formatContentNotificationBody(
  contentData: {[key: string]: any}
): string {
  switch (contentData.type) {
  case "trivia":
    return truncateText(contentData.content?.question ||
      "New trivia question!", 100);
  case "parent_tip":
    return truncateText(contentData.content?.title ||
      "New parent tip available!", 100);
  case "did_you_know":
    return truncateText(contentData.content?.fact ||
      "Discover something new!", 100);
  default:
    return "Check out the latest sports content!";
  }
}

/**
 * Get screen name for content type
 * @param {string} contentType Content type
 * @return {string} Screen name for mobile app
 */
function getContentScreenName(contentType: string): string {
  // Direct navigation to content detail screen for better UX
  return "content_detail";
}

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

/**
 * AI Content Generation Function
 * Generates trivia, parent tips, and did-you-know content using OpenAI
 */
export const generateUserContent = functions.https.onCall(
  async (data) => {
    // Verify admin authentication
    const adminEmail = data.adminEmail;
    if (!adminEmail) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Admin email required for content generation."
      );
    }

    // Verify admin exists and is active
    try {
      const adminSnapshot = await db.collection("admins")
        .where("email", "==", adminEmail)
        .where("isActive", "==", true)
        .limit(1)
        .get();

      if (adminSnapshot.empty) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Admin not found or inactive."
        );
      }

      const adminDoc = adminSnapshot.docs[0];
      const adminData = adminDoc.data();

      // Check if admin has super admin privileges for AI content
      if (adminData.role !== "super_admin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only super admins can generate AI content."
        );
      }

      console.log(`🔐 Super admin authenticated: ${adminData.displayName}`);
    } catch (authError) {
      console.error("❌ Admin authentication failed:", authError);
      if (authError instanceof functions.https.HttpsError) {
        throw authError;
      }
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Admin authentication failed."
      );
    }

    console.log("🤖 Starting AI content generation with data:", data);

    try {
      const {
        requestId,
        contentType,
        sportCategory,
        quantity = 5,
        difficulty = "medium",
        ageGroup,
        sourceType = "mixed",
      } = data;

      // Update request status to processing
      if (requestId) {
        await db.collection("content_generation_requests")
          .doc(requestId).update({
            status: "processing",
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
      }

      // Get sports wiki data if needed
      let sportsWikiData = null;
      if (sourceType === "sports_wiki" || sourceType === "mixed") {
        try {
          const wikiSnapshot = await db.collection("sports_wiki")
            .where("name", "==", sportCategory)
            .limit(1)
            .get();

          if (!wikiSnapshot.empty) {
            sportsWikiData = wikiSnapshot.docs[0].data();
            console.log(`📚 Found sports wiki data for ${sportCategory}`);
          }
        } catch (error) {
          console.log(`⚠️ Could not fetch wiki for ${sportCategory}:`, error);
        }
      }

      // Build context for AI
      const contextData = sportsWikiData ?
        buildSportsWikiContext(sportCategory, sportsWikiData) : "";

      // Generate AI prompt based on content type
      const prompt = buildContentPrompt(
        contentType,
        sportCategory,
        contextData,
        quantity,
        difficulty,
        ageGroup
      );

      console.log("📝 Generated prompt for AI:",
        prompt.substring(0, 200) + "...");

      // Call OpenAI API
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a sports content expert. Generate " +
              "engaging, accurate, and educational content about sports. " +
              "CRITICAL: Respond with ONLY valid JSON. No explanations, " +
              "no additional text, no markdown formatting. Just pure JSON.",
          },
          {
            role: "user",
            content: prompt +
              "\n\nIMPORTANT: Return ONLY valid JSON, nothing else.",
          },
        ],
        max_tokens: 3000,
        temperature: 0.7,
      });

      const aiResponse = response.choices[0].message.content;
      console.log("🤖 AI Response received:",
        aiResponse?.substring(0, 200) + "...");

      if (!aiResponse) {
        throw new Error("No response from AI");
      }

      // Parse AI response - extract JSON even if there's extra text
      let generatedContent;
      try {
        // First try direct parsing
        generatedContent = JSON.parse(aiResponse);
      } catch (parseError) {
        console.log("❌ Direct JSON parse failed, trying to extract JSON...");
        console.log("📝 Full AI Response:", aiResponse);
        // Try to extract JSON from the response
        try {
          // Look for JSON array or object patterns
          const jsonMatch = aiResponse.match(/\[[\s\S]*\]|\{[\s\S]*\}/);
          if (jsonMatch) {
            generatedContent = JSON.parse(jsonMatch[0]);
            console.log("✅ Successfully extracted JSON from response");
          } else {
            throw new Error("No JSON found in AI response");
          }
        } catch (extractError) {
          console.error("❌ Failed to extract JSON from AI response:",
            extractError);
          console.error("🔍 AI Response was:", aiResponse);
          throw new Error("Invalid JSON response from AI: " +
            (extractError as Error).message);
        }
      }

      // Save generated content to Firestore
      const generatedIds: string[] = [];
      const batch = db.batch();

      // Handle different content types
      if (Array.isArray(generatedContent)) {
        // Multiple items (like bulk trivia)
        for (const item of generatedContent) {
          const contentFeedData = formatContentForFirestore(
            contentType, item, sportCategory, sportsWikiData?.id
          );
          const docRef = db.collection("content_feeds").doc();
          batch.set(docRef, contentFeedData);
          generatedIds.push(docRef.id);
        }
      } else {
        // Single item
        const contentFeedData = formatContentForFirestore(
          contentType, generatedContent, sportCategory, sportsWikiData?.id
        );
        const docRef = db.collection("content_feeds").doc();
        batch.set(docRef, contentFeedData);
        generatedIds.push(docRef.id);
      }

      // Commit batch
      await batch.commit();

      console.log(`✅ Successfully generated ${generatedIds.length} items`);

      // Update generation request with results
      if (requestId) {
        await db.collection("content_generation_requests")
          .doc(requestId).update({
            status: "completed",
            generated_content_ids: generatedIds,
            completed_at: admin.firestore.FieldValue.serverTimestamp(),
          });
      }

      return {
        success: true,
        generatedCount: generatedIds.length,
        contentIds: generatedIds,
        message: `Successfully generated ${generatedIds.length} ` +
          `${contentType} items for ${sportCategory}`,
      };
    } catch (error: unknown) {
      console.error("❌ Content generation failed:", error);

      // Update request status to failed
      if (data.requestId) {
        await db.collection("content_generation_requests")
          .doc(data.requestId).update({
            status: "failed",
            error_message: (error as Error).message || "Unknown error",
            completed_at: admin.firestore.FieldValue.serverTimestamp(),
          });
      }

      throw new functions.https.HttpsError(
        "internal",
        `Content generation failed: ${(error as Error).message}`,
        {originalError: (error as Error).message}
      );
    }
  }
);

/**
 * Build context string from sports wiki data
 * @param {string} sportCategory - The sport category name
 * @param {any} sportsWikiData - The sports wiki data object
 * @return {string} Formatted context string for AI prompt
 */
function buildSportsWikiContext(
  sportCategory: string,
  sportsWikiData: any
): string {
  return `Sports Wiki Data for ${sportCategory}:
- Origin: ${sportsWikiData.origin || "Not specified"}
- Governing Body: ${sportsWikiData.governing_body || "Not specified"}
- Olympic Sport: ${sportsWikiData.olympic_sport ? "Yes" : "No"}
- Description: ${sportsWikiData.description || ""}
- Famous Athletes: ${sportsWikiData.famous_athletes?.join(", ") ||
    "Not specified"}
- Popular Events: ${sportsWikiData.popular_events?.join(", ") ||
    "Not specified"}
- Fun Facts: ${sportsWikiData.fun_facts?.join("\n- ") || "Not specified"}
- Equipment: ${sportsWikiData.equipment_needed?.join(", ") ||
    "Not specified"}
- Indian History: ${sportsWikiData.indian_milestones?.join("\n- ") ||
    "Not specified"}`;
}

/**
 * Helper function to build prompts for different content types
 * @param {string} contentType - Type of content to generate
 * @param {string} sportCategory - The sport category
 * @param {string} contextData - Context data from sports wiki
 * @param {number} quantity - Number of items to generate
 * @param {string} difficulty - Difficulty level for content
 * @param {string} ageGroup - Optional age group for targeting
 * @return {string} Generated prompt for AI
 */
function buildContentPrompt(
  contentType: string,
  sportCategory: string,
  contextData: string,
  quantity: number,
  difficulty: string,
  ageGroup?: string
): string {
  const baseContext = contextData ||
    `Generate content about ${sportCategory} sport.`;

  switch (contentType) {
  case "bulk_trivia": {
    return `${baseContext}

Generate ${quantity} ${difficulty} difficulty trivia questions about ` +
        `${sportCategory}.

Requirements:
- Questions should be engaging and educational
- Include 4 multiple choice options for each question
- Provide clear explanations for correct answers
- Vary question topics (rules, history, famous players, records, techniques)
- Make questions suitable for sports fans and general audiences

Return as JSON array with this exact structure:
[
  {
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correct_answer": "Option A",
    "explanation": "Detailed explanation why this is correct and context"
  }
]`;
  }

  case "single_parent_tip": {
    const ageText = ageGroup ? ` (for ages ${ageGroup})` : "";
    return `${baseContext}

Generate a comprehensive parent tip about why children should play ` +
        `${sportCategory}${ageText}.

Requirements:
- Create an engaging title
- List specific benefits (physical, mental, social, life skills)
- Write detailed content explaining why this sport is great for kids
- Include practical advice for parents
- Focus on development and character building
- Make it encouraging and informative

Return as JSON with this exact structure:
{
  "title": "Why [Sport] is Great for Kids",
  "benefits": ["Benefit 1", "Benefit 2", "Benefit 3", "Benefit 4"],
  "content": "Detailed explanation about why kids should play this sport...",
  "age_group": "${ageGroup || "6-16"}"
}`;
  }

  case "sport_facts": {
    return `${baseContext}

Generate ${quantity} fascinating "Did You Know" facts about ` +
        `${sportCategory} and famous athletes in this sport.

Requirements:
- Facts should be surprising and lesser-known
- Include historical moments, records, and interesting statistics
- Make facts engaging and shareable
- Vary topics (equipment, rules, famous players, Olympic history, records)
- Include specific details and context

Return as JSON array with this exact structure:
[
  {
    "fact": "Brief fascinating fact statement",
    "details": "Extended explanation with context, dates, names, story",
    "category": "records|history|equipment|players|rules"
  }
]`;
  }

  case "mixed_content": {
    const triviaCount = Math.floor(quantity * 0.5);
    const factsCount = Math.floor(quantity * 0.3);
    const tipsCount = Math.max(1, quantity - triviaCount - factsCount);

    return `${baseContext}

Generate mixed content for ${sportCategory}:
- ${triviaCount} trivia questions (${difficulty} difficulty)
- ${factsCount} "Did You Know" facts
- ${tipsCount} parent tip(s)

Return as JSON object with this exact structure:
{
  "trivia": [trivia questions array as specified above],
  "facts": [facts array as specified above],
  "parent_tips": [parent tips array as specified above]
}`;
  }

  default:
    return `${baseContext}

Generate engaging content about ${sportCategory}. Focus on educational ` +
        "and entertaining information that would interest sports fans.";
  }
}

/**
 * Helper function to format content for Firestore
 * @param {string} contentType - Type of content being formatted
 * @param {object} aiContent - AI generated content object
 * @param {string} sportCategory - The sport category
 * @param {string} wikiId - Optional sports wiki ID reference
 * @return {object} Formatted content ready for Firestore
 */
function formatContentForFirestore(
  contentType: string,
  aiContent: {[key: string]: any},
  sportCategory: string,
  wikiId?: string
): {[key: string]: any} {
  const baseData = {
    sport_category: sportCategory,
    status: "generated",
    generation_source: wikiId ? "sports_wiki" : "online_research",
    source_sport_wiki_id: wikiId || null,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    view_count: 0,
    like_count: 0,
  };

  switch (contentType) {
  case "bulk_trivia":
    return {
      ...baseData,
      type: "trivia",
      content: {
        question: aiContent.question,
        options: aiContent.options,
        correct_answer: aiContent.correct_answer,
        explanation: aiContent.explanation,
        difficulty: "medium", // Default if not specified
      },
    };

  case "single_parent_tip":
    return {
      ...baseData,
      type: "parent_tip",
      content: {
        title: aiContent.title,
        benefits: aiContent.benefits,
        content: aiContent.content,
        age_group: aiContent.age_group,
      },
    };

  case "sport_facts":
    return {
      ...baseData,
      type: "did_you_know",
      content: {
        fact: aiContent.fact,
        details: aiContent.details,
        category: aiContent.category,
      },
    };

  default:
    return {
      ...baseData,
      type: "did_you_know",
      content: aiContent,
    };
  }
}
