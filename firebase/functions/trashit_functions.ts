import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const POSTS = "trash_can_posts";

// Deletion policy: be conservative so posts don't vanish too quickly.
// A post is deleted only if total votes >= MIN_VOTES_TO_DELETE AND
// (untrash - retrash) >= REQUIRED_MARGIN.
const MIN_VOTES_TO_DELETE = 5;
const REQUIRED_MARGIN = 2;

function normalizeUrl(raw: string): string {
  try {
    const u = new URL(raw);
    const host = u.host.replace(/^www\./i, "").toLowerCase();
    // strip utm_* params
    const params = new URLSearchParams(u.search);
    Array.from(params.keys()).forEach((k) => {
      if (k.toLowerCase().startsWith("utm_")) params.delete(k);
    });
    let path = u.pathname;
    if (path.length > 1 && path.endsWith("/")) path = path.slice(0, -1);
    const q = params.toString();
    return `${u.protocol}//${host}${path}${q ? "?" + q : ""}`;
  } catch {
    return raw;
  }
}

export const trashitCreateOrRetrash = functions.https.onCall(async (data, context) => {
  const url = String(data.url || "").trim();
  const title = String(data.title || "Shared Content").trim();
  const hashtags: string[] = Array.isArray(data.hashtags) ? data.hashtags : [];
  const deviceId = String(data.deviceId || "").trim();
  const imageUrl = String(data.imageUrl || "").trim();

  if (!url || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing url or deviceId");
  }

  const norm = normalizeUrl(url);

  // Try to find existing post by URL
  const existingSnap = await db.collection(POSTS).where("url", "==", norm).limit(1).get();
  if (!existingSnap.empty) {
    const doc = existingSnap.docs[0];
    const post = doc.data();

    if (post.device_id === deviceId) {
      throw new functions.https.HttpsError("failed-precondition", "You have already trashed this post");
    }

    const retrashVotes: string[] = Array.isArray(post.retrash_votes) ? post.retrash_votes : [];
    const untrashVotes: string[] = Array.isArray(post.untrash_votes) ? post.untrash_votes : [];

    if (retrashVotes.includes(deviceId) || untrashVotes.includes(deviceId)) {
      throw new functions.https.HttpsError("failed-precondition", "You have already voted on this post");
    }

    const retrashVotesArr: string[] = Array.isArray(post.retrash_votes)
      ? post.retrash_votes.filter((x: any) => typeof x === "string" && x)
      : [];
    const nextRetrashVotes = Array.from(new Set([...retrashVotesArr, deviceId]));

    await doc.ref.update({
      retrash_count: (post.retrash_count || 0) + 1,
      retrash_votes: nextRetrashVotes,
    });

    return { status: "ok", action: "retrash_existing" };
  }

  // Create new post with initial vote by owner
  const now = admin.firestore.Timestamp.now();
  await db.collection(POSTS).add({
    url: norm,
    title,
    hashtags,
    retrash_count: 1,
    untrash_count: 0,
    device_id: deviceId,
    timestamp: now,
    image_url: imageUrl,
    ai_summary: null, // Can be filled by a separate function/cron if needed
    retrash_votes: [deviceId],
    untrash_votes: [],
  });

  return { status: "ok", action: "create" };
});

export const trashitVote = functions.https.onCall(async (data, context) => {
  const postId = String(data.postId || "").trim();
  const deviceId = String(data.deviceId || "").trim();
  const isRetrash = Boolean(data.isRetrash);

  if (!postId || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing postId or deviceId");
  }

  const ref = db.collection(POSTS).doc(postId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const post = snap.data()!;

    if (post.device_id === deviceId) {
      if (isRetrash) {
        throw new functions.https.HttpsError("failed-precondition", "You can't retrash your own post");
      } else {
        throw new functions.https.HttpsError("failed-precondition", "You can't untrash your own post. You can delete it instead");
      }
    }

    const retrashVotes: string[] = Array.isArray(post.retrash_votes) ? post.retrash_votes : [];
    const untrashVotes: string[] = Array.isArray(post.untrash_votes) ? post.untrash_votes : [];

    if (retrashVotes.includes(deviceId) || untrashVotes.includes(deviceId)) {
      throw new functions.https.HttpsError("failed-precondition", "You have already voted on this post");
    }

    // Sanitize arrays and compute next state
    const rvSan = retrashVotes.filter((x) => typeof x === "string" && x);
    const uvSan = untrashVotes.filter((x) => typeof x === "string" && x);

    if (isRetrash) {
      const nextRV = Array.from(new Set([...rvSan, deviceId]));
      const nextUV = Array.from(new Set([...uvSan]));
      const nextRetrash = nextRV.length;
      const nextUntrash = nextUV.length;

      const totalVotes = nextRetrash + nextUntrash;
      const shouldDelete = totalVotes >= MIN_VOTES_TO_DELETE && (nextUntrash - nextRetrash) >= REQUIRED_MARGIN;
      if (shouldDelete) {
        tx.delete(ref);
        return;
      }

      tx.update(ref, {
        retrash_count: nextRetrash,
        untrash_count: nextUntrash,
        retrash_votes: nextRV,
        untrash_votes: nextUV,
      });
    } else {
      const nextUV = Array.from(new Set([...uvSan, deviceId]));
      const nextRV = Array.from(new Set([...rvSan]));
      const nextRetrash = nextRV.length;
      const nextUntrash = nextUV.length;

      const totalVotes = nextRetrash + nextUntrash;
      const shouldDelete = totalVotes >= MIN_VOTES_TO_DELETE && (nextUntrash - nextRetrash) >= REQUIRED_MARGIN;
      if (shouldDelete) {
        tx.delete(ref);
        return;
      }

      tx.update(ref, {
        retrash_count: nextRetrash,
        untrash_count: nextUntrash,
        retrash_votes: nextRV,
        untrash_votes: nextUV,
      });
    }
  });

  return { status: "ok" };
});

export const trashitUndoVote = functions.https.onCall(async (data, context) => {
  const postId = String(data.postId || "").trim();
  const deviceId = String(data.deviceId || "").trim();
  const isRetrash = Boolean(data.isRetrash);

  if (!postId || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing postId or deviceId");
  }

  const ref = db.collection(POSTS).doc(postId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return; // if post was deleted, noop
    const post = snap.data()!;

    // Sanitize
    let rv: string[] = Array.isArray(post.retrash_votes) ? post.retrash_votes.filter((x: any) => typeof x === "string" && x) : [];
    let uv: string[] = Array.isArray(post.untrash_votes) ? post.untrash_votes.filter((x: any) => typeof x === "string" && x) : [];

    if (isRetrash) {
      rv = rv.filter((x) => x !== deviceId);
    } else {
      uv = uv.filter((x) => x !== deviceId);
    }

    const nextRetrash = rv.length;
    const nextUntrash = uv.length;

    // If after undo post becomes non-positive or invalid, we keep it but clamp counts
    tx.update(ref, {
      retrash_count: nextRetrash,
      untrash_count: nextUntrash,
      retrash_votes: rv,
      untrash_votes: uv,
    });
  });

  return { status: "ok", action: "undone" };
});

export const trashitDeleteOwnedPost = functions.https.onCall(async (data, context) => {
  const postId = String(data.postId || "").trim();
  const deviceId = String(data.deviceId || "").trim();

  if (!postId || !deviceId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing postId or deviceId");
  }

  const ref = db.collection(POSTS).doc(postId);
  const snap = await ref.get();
  if (!snap.exists) return { status: "ok", action: "noop" };
  const post = snap.data()!;

  if (post.device_id !== deviceId) {
    throw new functions.https.HttpsError("permission-denied", "Only the original trasher can delete this post");
  }

  await ref.delete();
  return { status: "ok", action: "deleted" };
});

// Admin-only maintenance to recalc counts, sanitize votes arrays and cleanup old or invalid posts.
// Protect with an admin key stored in functions config: `firebase functions:config:set trashit.admin_key=YOUR_SECRET`
// In Dreamflow, set this in the Firebase panel under Functions > Runtime config.
export const trashitAdminRecalcAndCleanup = functions.https.onCall(async (data, context) => {
  // Validate admin secret
  const providedKey = String(data?.adminKey || "").trim();
  const cfg: any = functions.config() || {};
  const expectedKey = cfg?.trashit?.admin_key ? String(cfg.trashit.admin_key) : "";
  if (!expectedKey || providedKey !== expectedKey) {
    throw new functions.https.HttpsError("permission-denied", "Invalid admin key");
  }

  const dryRun = Boolean(data?.dryRun);
  const olderThanDaysRaw = Number(data?.olderThanDays);
  const olderThanDays = Number.isFinite(olderThanDaysRaw) && olderThanDaysRaw > 0 ? olderThanDaysRaw : 90;

  const now = admin.firestore.Timestamp.now();
  const cutoffMillis = now.toMillis() - olderThanDays * 24 * 60 * 60 * 1000;
  const cutoff = admin.firestore.Timestamp.fromMillis(cutoffMillis);

  const batchSize = 300;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;

  let processed = 0;
  let fixedCounts = 0;
  let deleted = 0;

  while (true) {
    let q = db.collection(POSTS).orderBy("timestamp").limit(batchSize);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();

    for (const doc of snap.docs) {
      processed += 1;
      const d = doc.data() as any;

      const rv = Array.isArray(d?.retrash_votes) ? d.retrash_votes.filter((x: any) => typeof x === "string" && x) : [];
      const uv = Array.isArray(d?.untrash_votes) ? d.untrash_votes.filter((x: any) => typeof x === "string" && x) : [];

      const calcRetrash = rv.length;
      const calcUntrash = uv.length;

      const ts: admin.firestore.Timestamp | null = d?.timestamp instanceof admin.firestore.Timestamp ? d.timestamp : null;

      const isOld = ts ? ts.toMillis() < cutoffMillis : false;
      const nonPositiveScore = (calcRetrash - calcUntrash) <= 0;

      const total = calcRetrash + calcUntrash;
      const scoreMargin = (calcUntrash - calcRetrash);
      const shouldDeleteByVotes = total >= MIN_VOTES_TO_DELETE && scoreMargin >= REQUIRED_MARGIN;

      const mustDelete = shouldDeleteByVotes || (isOld && nonPositiveScore);
      const countsMismatch = (d?.retrash_count !== calcRetrash) || (d?.untrash_count !== calcUntrash);

      if (mustDelete) {
        if (!dryRun) batch.delete(doc.ref);
        deleted += 1;
        continue;
      }

      if (countsMismatch || rv.length !== (Array.isArray(d?.retrash_votes) ? d.retrash_votes.length : 0) || uv.length !== (Array.isArray(d?.untrash_votes) ? d.untrash_votes.length : 0)) {
        if (!dryRun) batch.update(doc.ref, {
          retrash_count: calcRetrash,
          untrash_count: calcUntrash,
          retrash_votes: rv,
          untrash_votes: uv,
        });
        fixedCounts += 1;
      }
    }

    if (!dryRun) await batch.commit();

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < batchSize) break;
  }

  return { status: "ok", dryRun, olderThanDays, processed, fixedCounts, deleted };
});
