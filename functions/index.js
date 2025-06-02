const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");

const DEFAULT_AVATAR_URL = "assets/images/premium_logo.png";

admin.initializeApp();

const PAYSTACK_SECRET_KEY = "sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23";

/**
 * Initialize Paystack payment for premium community upgrade/creation.
 */
exports.createPremiumPayment = functions.https.onRequest(async (req, res) => {
  const {userId, email, communityName, bio, requiresVerification} = req.body;

  if (!userId || !email || !communityName) {
    return res.status(400).json({error: "Missing required data"});
  }

  const reference = `premium-upgrade-${userId}-${Date.now()}`;

  const paystackPayload = {
    email,
    amount: 500000, // amount in kobo (5000 NGN)
    reference,
    metadata: {
      userId,
      communityName,
      bio,
      requiresVerification: requiresVerification.toString(),
    },
  };

  try {
    const response = await fetch(
        "https://api.paystack.co/transaction/initialize",
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(paystackPayload),
        },
    );

    const body = await response.json();

    if (!body.status) {
      return res.status(500).json({error: "Failed to initialize payment"});
    }

    await admin.firestore().collection("premiumPayments").doc(reference).set({
      userId,
      communityName,
      bio,
      requiresVerification,
      status: "pending",
      amount: 500000,
      reference,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      paymentUrl: body.data.authorization_url,
      reference,
    });
  } catch (error) {
    return res.status(500).json({error: error.message || "Unknown error"});
  }
});

/**
 * Callable function to check if a community name exists.
 */
exports.checkCommunityNameExists = functions.https.onCall(
    async (data, context) => {
      const {communityName} = data;

      if (!communityName) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing communityName",
        );
      }

      const communitiesRef = admin.firestore().collection("communities");
      const snapshot =
      await communitiesRef.where("name", "==", communityName).get();

      return {exists: !snapshot.empty};
    },
);

/**
 * Paystack webhook to verify payment and create/upgrade premium community.
 */
exports.paystackWebhook = functions.https.onRequest(async (req, res) => {
  // Verify webhook signature
  const hash = crypto
      .createHmac("sha512", PAYSTACK_SECRET_KEY)
      .update(JSON.stringify(req.body))
      .digest("hex");

  if (hash !== req.headers["x-paystack-signature"]) {
    console.error("Invalid Paystack signature");
    return res.status(400).send("Invalid signature");
  }

  const event = req.body;

  if (event.event === "charge.success") {
    const charge = event.data;

    const userId = charge.metadata.userId;
    const communityName = charge.metadata.communityName;
    const bio = charge.metadata.bio || "";
    const requiresVerification =
      charge.metadata.requiresVerification === "true" ||
      charge.metadata.requiresVerification === true;

    if (!userId || !communityName) {
      console.error("Missing metadata in webhook");
      return res.status(400).send("Missing metadata");
    }

    try {
      const communitiesRef = admin.firestore().collection("communities");
      const existingCommunitySnapshot = await communitiesRef
          .where("name", "==", communityName)
          .get();

      if (!existingCommunitySnapshot.empty) {
        // Upgrade existing community to premium
        const communityDoc = existingCommunitySnapshot.docs[0];
        await communityDoc.ref.update({
          communityType: "premium",
          bio,
          requiresVerification,
        });

        console.log(`Upgraded community '${communityName}' to premium.`);
      } else {
        // Create new premium community
        const communityRef = communitiesRef.doc();

        await communityRef.set({
          id: communityRef.id,
          name: communityName,
          bio,
          requiresVerification,
          communityType: "premium",
          creatorUid: userId,
          members: [userId],
          mods: [userId],
          bannedUsers: [],
          pendingMembers: [],
          avatar: DEFAULT_AVATAR_URL,
          balance: 0.0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(
            `Created premium community: ${communityName} for user: ${userId}`,
        );
      }

      // Update payment status to successful
      const paymentRef = admin
          .firestore()
          .collection("premiumPayments")
          .doc(charge.reference);

      await paymentRef.update({
        status: "successful",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).send("Webhook processed");
    } catch (error) {
      console.error("Error processing webhook:", error);
      return res.status(500).send("Internal server error");
    }
  } else {
    // Ignore other event types
    return res.status(200).send("Event ignored");
  }
});

const APPLE_PRODUCTION_VERIFY_URL = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_SANDBOX_VERIFY_URL = "https://sandbox.itunes.apple.com/verifyReceipt";

/**
 * Verify Apple receipt with production and fallback sandbox endpoint.
 *
 * @param {string} receiptData Apple base64 encoded receipt data
 * @return {Promise<Object>} Apple receipt verification response JSON
 */
async function verifyAppleReceipt(receiptData) {
  const body = {
    "receipt-data": receiptData,
    "exclude-old-transactions": true,
  };

  let response = await fetch(APPLE_PRODUCTION_VERIFY_URL, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(body),
  });

  let data = await response.json();

  if (data.status === 21007) {
    response = await fetch(APPLE_SANDBOX_VERIFY_URL, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(body),
    });

    data = await response.json();
  }

  return data;
}

/**
 * Verify Apple IAP receipt, create/upgrade premium community,
 * and record payment in Firestore.
 */
exports.verifyAppleIAP = functions.https.onRequest(async (req, res) => {
  try {
    const {userId, communityName, bio, requiresVerification, receiptData} =
      req.body;

    if (!userId || !communityName || !receiptData) {
      return res.status(400).json({
        error: "Missing required fields: userId, communityName or receiptData",
      });
    }

    const appleResponse = await verifyAppleReceipt(receiptData);

    if (appleResponse.status !== 0) {
      return res.status(400).json({
        error:
        `Apple receipt verification failed with status:
         ${appleResponse.status}`,
      });
    }

    const communitiesRef = admin.firestore().collection("communities");
    const existingCommunitySnapshot = await communitiesRef
        .where("name", "==", communityName)
        .get();

    if (!existingCommunitySnapshot.empty) {
      const communityDoc = existingCommunitySnapshot.docs[0];
      await communityDoc.ref.update({
        communityType: "premium",
        bio: bio || "",
        requiresVerification: !!requiresVerification,
      });

      console.log(`Upgraded community '${communityName}' to premium.`);
    } else {
      const communityRef = communitiesRef.doc();

      await communityRef.set({
        id: communityRef.id,
        name: communityName,
        bio: bio || "",
        requiresVerification: !!requiresVerification,
        communityType: "premium",
        creatorUid: userId,
        members: [userId],
        mods: [userId],
        bannedUsers: [],
        pendingMembers: [],
        avatar: "assets/images/premium_logo.png",
        balance: 0.0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
          `Created premium community '${communityName}' for user ${userId}.`,
      );
    }

    const paymentsRef = admin.firestore().collection("premiumPayments");
    await paymentsRef.add({
      userId,
      communityName,
      bio: bio || "",
      requiresVerification: !!requiresVerification,
      paymentMethod: "apple_iap",
      paymentStatus: "successful",
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      appleReceipt: receiptData,
    });

    return res.status(200).json({
      message: "Receipt verified and community upgraded/created successfully",
    });
  } catch (error) {
    console.error("Error verifying Apple IAP:", error);
    return res.status(500).json({error: "Internal server error"});
  }
});
