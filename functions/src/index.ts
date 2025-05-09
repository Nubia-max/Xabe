import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
admin.initializeApp();
const FLAG_THRESHOLD = 3;

export const onReportCreated = onDocumentCreated(
  'reports/{reportId}',
  async (event) => {
    // 1) Guard: bail out if no snapshot
    if (!event.data) return null;

    // 2) Now safe to extract data
    const report = event.data.data()!;
    const { contentId, communityId } = report as { contentId: string; communityId: string };

    // 3) Count existing flags
    const reportsSnap = await admin
      .firestore()
      .collection('reports')
      .where('contentId', '==', contentId)
      .get();
    if (reportsSnap.size < FLAG_THRESHOLD) return null;

    // 4) Enqueue if not already
    const queueRef = admin.firestore().collection('moderationQueue').doc(contentId);
    if ((await queueRef.get()).exists) return null;
    await queueRef.set({
      contentId,
      communityId,
      flagCount: reportsSnap.size,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    // 5) Send community-scoped FCM
    const topic = `moderators-${communityId}`;
    const payload = {
      notification: {
        title: '🚩 Post Needs Review',
        body: `A post in community ${communityId} has ${reportsSnap.size} flags.`,
      },
      data: { contentId, communityId }
    };
    await admin.messaging().sendToTopic(topic, payload);

    return null;
  }
);
