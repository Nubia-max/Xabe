const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");
const DEFAULT_AVATAR_URL = "assets/images/premium_logo.png";

admin.initializeApp();

const PAYSTACK_SECRET_KEY = "sk_live_081a6b72526a9c7fcda22c9f194272fa9ac84e23";

exports.createPremiumPayment = functions.https.onRequest(async (req, res) => {
  const {userId, email, communityName, bio, requiresVerification} = req.body;

  if (!userId || !email || !communityName) {
    return res.status(400).json({error: "Missing required data"});
  }

  const reference = `premium-upgrade-${userId}-${Date.now()}`;

  const paystackPayload = {
    email: email,
    amount: 50000,
    reference: reference,
    metadata: {
      userId: userId,
      communityName: communityName,
      bio: bio,
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
      userId: userId,
      communityName: communityName,
      bio: bio,
      requiresVerification: requiresVerification,
      status: "pending",
      amount: 50000,
      reference: reference,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      paymentUrl: body.data.authorization_url,
      reference: reference,
    });
  } catch (error) {
    return res.status(500).json({error: error.message || "Unknown error"});
  }
});

exports.checkCommunityNameExists =
functions.https.onCall(async (data, context) => {
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
});

exports.paystackWebhook = functions.https.onRequest(async (req, res) => {
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
      const existingCommunity = await communitiesRef
          .where("name", "==", communityName)
          .get();

      if (!existingCommunity.empty) {
        console.log(`Community with name ${communityName} already exists.`);
        return res.status(200).send("Community already exists");
      }

      const communityRef = communitiesRef.doc();

      await communityRef.set({
        id: communityRef.id,
        name: communityName,
        bio: bio,
        requiresVerification: requiresVerification,
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

      const paymentRef = admin.firestore()
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
    return res.status(200).send("Event ignored");
  }
});
