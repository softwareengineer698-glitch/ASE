/**
 * FoodBridge – Firebase Cloud Functions v2
 * Push notification triggers for FCM delivery.
 *
 * Deploy with:
 *   firebase deploy --only functions
 *
 * Requires Blaze (pay-as-you-go) billing plan.
 * Run `npm install` inside the functions/ directory before deploying.
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { defineSecret } = require("firebase-functions/params");

initializeApp();
const db = getFirestore();

// Secret stored in Firebase Secret Manager (never in code)
// Set with: firebase functions:secrets:set OPENAI_API_KEY
const openaiKey = defineSecret("OPENAI_API_KEY");

// ── Helper: fetch FCM token + notificationsEnabled flag for a user ─────────
async function getToken(userId) {
  if (!userId) return null;
  const snap = await db.collection("users").doc(userId).get();
  if (!snap.exists) return null;
  const data = snap.data();
  if (data.notificationsEnabled === false) return null;
  return data.fcmToken || null;
}

// ── Helper: send a push, silently ignore missing tokens ───────────────────
async function sendPush(token, title, body, data = {}) {
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      data: { ...data },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  } catch (err) {
    // Token may be stale – not fatal
    console.error("FCM send error:", err.message);
  }
}

async function getRecipientTokens() {
  return getTokensByRole("ngo");
}

async function getTokensByRole(role) {
  const snap = await db
    .collection("users")
    .where("role", "==", role)
    .where("notificationsEnabled", "!=", false)
    .get();
  return snap.docs.map((doc) => doc.data().fcmToken).filter(Boolean);
}

// ── 0. New donation posted → notify recipients ────────────────────────────
exports.onDonationCreated = onDocumentCreated("donations/{donationId}", async (event) => {
  const donation = event.data.data();
  const tokens = await getRecipientTokens();
  for (const token of tokens) {
    await sendPush(
      token,
      "New Food Available Nearby",
      `${donation.title || "A donation"} is available for claiming.`,
      {
        type: "surplusReported",
        donationId: event.params.donationId,
        notificationId: `fcm_donation_${event.params.donationId}`,
        actionData: "surplus_list",
      }
    );
  }
});

// ── 0b. New food request posted → notify donors ───────────────────────────
exports.onFoodRequestCreated = onDocumentCreated("food_requests/{requestId}", async (event) => {
  const request = event.data.data();
  const tokens = await getTokensByRole("donor");
  const quantity = request.quantity ? `${request.quantity} ${request.unit || "units"} of ` : "";
  const requestTitle = request.foodType || "food";
  const requester = request.organizationName || request.userName || "An NGO";

  for (const token of tokens) {
    await sendPush(
      token,
      "New Food Request 📋",
      `${requester} requested ${quantity}${requestTitle}.`,
      {
        type: "requestCreated",
        requestId: event.params.requestId,
        notificationId: `fcm_food_request_${event.params.requestId}`,
        actionData: "request_list",
      }
    );
  }
});

// ── 1. New claim submitted → notify donor ─────────────────────────────────
exports.onClaimCreated = onDocumentCreated("claims/{claimId}", async (event) => {
  const claim = event.data.data();
  const token = await getToken(claim.donorId);
  await sendPush(
    token,
    "New Claim Request 📋",
    `Someone wants to claim ${claim.claimedQuantity} ${claim.unit} of your donation.`,
    {
      type: "claimReceived",
      donationId: claim.donationId,
      notificationId: `fcm_claim_${event.params.claimId}`,
      actionData: "donor_dashboard",
    }
  );
});

// ── 1b. NGO requests volunteer transport → notify donor ───────────────────
exports.onDeliveryCreated = onDocumentCreated("deliveries/{deliveryId}", async (event) => {
  const delivery = event.data.data();
  const token = await getToken(delivery.donorId);
  if (!token) return;

  let ngoName = String(delivery.ngoName || "").trim() || "An NGO";
  let donationTitle = String(delivery.donationTitle || "").trim() || "your donation";

  try {
    if (!String(delivery.ngoName || "").trim() && delivery.ngoId) {
      const ngoSnap = await db.collection("users").doc(delivery.ngoId).get();
      const ngoData = ngoSnap.data() || {};
      ngoName =
        ngoData.organizationName ||
        ngoData.userName ||
        ngoData.email ||
        ngoName;
    }

    if (!String(delivery.donationTitle || "").trim() && delivery.donationId) {
      const donationSnap = await db.collection("donations").doc(delivery.donationId).get();
      const donationData = donationSnap.data() || {};
      donationTitle = donationData.title || donationTitle;
    }
  } catch (err) {
    console.error("Volunteer request lookup error:", err.message);
  }

  await sendPush(
    token,
    "Volunteer Requested",
    `${ngoName} requested a volunteer for ${donationTitle}.`,
    {
      type: "general",
      donationId: delivery.donationId || "",
      notificationId: `fcm_delivery_${event.params.deliveryId}`,
      actionData: "donor_dashboard",
    }
  );
});

// ── 2. Claim accepted → notify recipient ──────────────────────────────────
exports.onClaimAccepted = onDocumentUpdated("claims/{claimId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return; // no status change

  if (after.status === "accepted") {
    const token = await getToken(after.claimantId);
    await sendPush(
      token,
      "Claim Approved! ✅",
      "Your claim has been accepted. Open chat to coordinate pickup.",
      {
        type: "claimAccepted",
        donationId: after.donationId,
        notificationId: `fcm_accepted_${event.params.claimId}`,
        actionData: "ngo_dashboard",
      }
    );
  }

  if (after.status === "rejected") {
    const token = await getToken(after.claimantId);
    await sendPush(
      token,
      "Claim Not Approved 😔",
      "Your claim was not approved. Other donations may still be available.",
      {
        type: "claimRejected",
        donationId: after.donationId,
        notificationId: `fcm_rejected_${event.params.claimId}`,
        actionData: "ngo_dashboard",
      }
    );
  }
});

// ── 3. New chat message → notify the other participant ────────────────────
exports.onChatMessage = onDocumentCreated(
  "chat_rooms/{roomId}/messages/{msgId}",
  async (event) => {
    const msg = event.data.data();
    const roomSnap = await db.collection("chat_rooms").doc(event.params.roomId).get();
    if (!roomSnap.exists) return;
    const room = roomSnap.data();
    const participants = room.participantIds || [];
    const senderSnap = await db.collection("users").doc(msg.senderId).get();
    const senderData = senderSnap.data() || {};
    const senderName =
      senderData.userName ||
      senderData.organizationName ||
      senderData.email ||
      "FoodBridge";
    // Notify everyone except the sender
    const recipients = participants.filter((id) => id !== msg.senderId);
    for (const uid of recipients) {
      const token = await getToken(uid);
      await sendPush(
        token,
        `New Message from ${senderName}`,
        msg.text && msg.text.length > 80 ? msg.text.substring(0, 80) + "…" : msg.text,
        {
          type: "newMessage",
          notificationId: `fcm_msg_${event.params.msgId}`,
          chatRoomId: event.params.roomId,
          otherUserName: String(senderName),
          actionData: `chat_${event.params.roomId}`,
        }
      );
    }
  }
);

// ── 4. Donation expiring soon → notify donor ─────────────────────────────
//    Triggered when expiryTime field is updated on a donation document.
exports.onDonationExpiryWarning = onDocumentUpdated(
  "donations/{donationId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    // Trigger only when status changes to "available" or "partiallyClaimed"
    // and expiry is within 24 hours – Cloud Functions don't support scheduled
    // per-document timers; use the DonationExpiryService on the client for
    // time-based checks. This trigger handles status transitions.
    if (before.status === after.status) return;
    const expiry = after.expiryTime ? new Date(after.expiryTime) : null;
    if (!expiry) return;
    const hoursLeft = (expiry - Date.now()) / 3600000;
    if (hoursLeft > 0 && hoursLeft <= 24) {
      const token = await getToken(after.donorId);
      await sendPush(
        token,
        "Food Expiring Soon! ⚠️",
        `${after.title} will expire in ${Math.round(hoursLeft)} hours.`,
        {
          type: "expiryReminder",
          donationId: event.params.donationId,
          notificationId: `fcm_expiry_${event.params.donationId}`,
          actionData: "donor_dashboard",
        }
      );
    }
  }
);

// ── 5. Food request fulfilled → notify the requester ─────────────────────
exports.onRequestFulfilled = onDocumentUpdated(
  "food_requests/{requestId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === after.status) return;
    if (after.status !== "fulfilled") return;
    const token = await getToken(after.userId);
    await sendPush(
      token,
      "Request Fulfilled! 🎁",
      `${after.fulfilledByDonorName || "A donor"} has provided the ${after.foodType} you requested.`,
      {
        type: "requestFulfilled",
        requestId: event.params.requestId,
        notificationId: `fcm_req_${event.params.requestId}`,
        actionData: "my_requests",
      }
    );
  }
);

// ── 6. Whisper speech-to-text proxy ───────────────────────────────────────
// Receives multipart audio from the Flutter client, forwards to OpenAI
// Whisper API, and returns { "text": "..." }.
// The OpenAI key is stored in Firebase Secret Manager — never in the client.
//
// Store the secret before deploying:
//   firebase functions:secrets:set OPENAI_API_KEY
//
// After deploying, copy the function URL into
//   lib/services/whisper_service.dart → _proxyUrl
exports.whisperTranscribe = onRequest(
  { secrets: [openaiKey], timeoutSeconds: 120, memory: "256MiB" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      // Re-stream the incoming multipart body directly to OpenAI
      const fetch = (await import("node-fetch")).default;
      const FormData = (await import("form-data")).default;

      const form = new FormData();
      // req.rawBody is a Buffer (Cloud Functions v2 with rawBody enabled)
      form.append("file", req.rawBody, {
        filename: "audio.m4a",
        contentType: req.headers["content-type"]?.split(";")[0] || "audio/m4a",
      });
      form.append("model", "whisper-1");

      const response = await fetch(
        "https://api.openai.com/v1/audio/transcriptions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${openaiKey.value()}`,
            ...form.getHeaders(),
          },
          body: form,
        }
      );

      const data = await response.json();
      if (!response.ok) {
        console.error("OpenAI error:", data);
        res.status(response.status).json(data);
        return;
      }
      res.json({ text: data.text || "" });
    } catch (err) {
      console.error("whisperTranscribe error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);
