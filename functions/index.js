// functions/index.js

const { onCall } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { Configuration, OpenAIApi } = require("openai");
const admin = require("firebase-admin");

// Initialize Firebase Admin if not already
admin.initializeApp();

// Read your OpenAI key from Functions config
const openaiKey = process.env.OPENAI_API_KEY ||
  (() => {
    const cfg = require("firebase-functions").config();
    return cfg.openai && cfg.openai.key;
  })();

if (!openaiKey) {
  throw new Error(
    "OpenAI API key not found. Run: firebase functions:config:set openai.key=\"YOUR_KEY\""
  );
}

// Configure OpenAI
const openai = new OpenAIApi(new Configuration({
  apiKey: openaiKey,
}));

/**
 * Callable function: moderateText
 * Input: { text: string }
 * Output: { allowed: boolean, categories?: object }
 */
exports.moderateText = onCall(async (req, resp) => {
  const data = req.data || {};
  const text = data.text;
  if (typeof text !== "string") {
    resp.status = 400;
    return { error: 'The function must be called with a "text" string.' };
  }

  try {
    const moderation = await openai.createModeration({ input: text });
    const result = moderation.data.results[0];
    const allowed = !result.flagged;

    logger.info("Moderation result", {
      text: text.slice(0, 50),
      flagged: result.flagged,
      categories: result.category_scores
    });

    return { allowed, categories: result.category_scores };
  } catch (err) {
    logger.error("Error calling OpenAI moderation:", err);
    resp.status = 500;
    return { error: "Moderation service failed." };
  }
});
