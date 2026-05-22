import * as admin from "firebase-admin";
import * as auth from "firebase-admin/auth";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

export const onUserCreated = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    try {
      await auth.getAuth().setCustomUserClaims(uid, {role: "socio"});
      await db.collection("users").doc(uid).update({role: "socio"});
    } catch (err) {
      console.error("Error setting custom claims:", err);
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Admin: set user role (callable — admin only)
// ────────────────────────────────────────────────────────────────────────────
export const setUserRole = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const callerRole = request.auth?.token?.role as string | undefined;
    if (callerRole !== "admin") {
      throw new HttpsError(
        "permission-denied",
        "Solo los administradores pueden cambiar roles."
      );
    }

    const {uid, role} = request.data as {uid: string; role: string};
    if (!uid || !role) {
      throw new HttpsError("invalid-argument", "uid y role son requeridos.");
    }

    const validRoles = ["socio", "entrenador", "admin"];
    if (!validRoles.includes(role)) {
      throw new HttpsError("invalid-argument", "Rol inválido.");
    }

    try {
      await auth.getAuth().setCustomUserClaims(uid, {role});
      await db.collection("users").doc(uid).update({role});
      return {success: true};
    } catch (err) {
      throw new HttpsError("internal", "Error al cambiar el rol.");
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Events: push notification on new event
// ────────────────────────────────────────────────────────────────────────────
export const onEventCreated = onDocumentCreated(
  "events/{eventId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    await messaging.send({
      topic: "socios",
      notification: {
        title: "Nuevo evento: " + (data.title as string),
        body: data.description
          ? (data.description as string).slice(0, 80)
          : "Apúntate ahora",
      },
      data: {
        eventId: event.params.eventId,
        type: "new_event",
      },
      android: {priority: "high"},
      apns: {payload: {aps: {contentAvailable: true}}},
    });
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Events: transactional registration (callable)
// ────────────────────────────────────────────────────────────────────────────
export const registerForEvent = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Debes estar autenticado.");

    const {eventId} = request.data as {eventId: string};
    if (!eventId) throw new HttpsError("invalid-argument", "eventId requerido.");

    const eventRef = db.collection("events").doc(eventId);
    const registrationRef = eventRef.collection("registrations").doc(uid);

    try {
      await db.runTransaction(async (t) => {
        const eventDoc = await t.get(eventRef);
        if (!eventDoc.exists) {
          throw new HttpsError("not-found", "Evento no encontrado.");
        }

        const data = eventDoc.data()!;
        const capacity = data.capacity as number;
        const registered = data.registeredCount as number;

        if (registered >= capacity) {
          throw new HttpsError(
            "resource-exhausted",
            "No quedan plazas disponibles."
          );
        }

        const regDoc = await t.get(registrationRef);
        if (regDoc.exists) {
          throw new HttpsError("already-exists", "Ya estás inscrito.");
        }

        t.set(registrationRef, {
          status: "confirmed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        t.update(eventRef, {
          registeredCount: admin.firestore.FieldValue.increment(1),
        });
      });

      return {success: true};
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError("internal", "Error al inscribirse.");
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Rankings: ELO computation on match creation
// ────────────────────────────────────────────────────────────────────────────
function computeNewRating(
  current: number,
  opponent: number,
  won: boolean,
  k = 32
): number {
  const expected = 1 / (1 + Math.pow(10, (opponent - current) / 400));
  const score = won ? 1.0 : 0.0;
  return Math.round(current + k * (score - expected));
}

export const onMatchCreated = onDocumentCreated(
  "rankings/{userId}/history/{matchId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const playerAId = event.params.userId;
    const {opponentId, won, ratingBefore} = data as {
      opponentId: string;
      won: boolean;
      ratingBefore: number;
    };

    const aRef = db.collection("rankings").doc(playerAId);
    const bRef = db.collection("rankings").doc(opponentId);
    const matchRef = event.data?.ref;

    await db.runTransaction(async (t) => {
      const aDoc = await t.get(aRef);
      const bDoc = await t.get(bRef);

      const aPoints = (aDoc.data()?.points as number) ?? ratingBefore ?? 1200;
      const bPoints = (bDoc.data()?.points as number) ?? 1200;

      const newA = computeNewRating(aPoints, bPoints, won);
      const newB = computeNewRating(bPoints, aPoints, !won);

      const now = admin.firestore.FieldValue.serverTimestamp();

      t.set(
        aRef,
        {
          points: newA,
          wins: admin.firestore.FieldValue.increment(won ? 1 : 0),
          losses: admin.firestore.FieldValue.increment(won ? 0 : 1),
          updatedAt: now,
        },
        {merge: true}
      );

      t.set(
        bRef,
        {
          points: newB,
          wins: admin.firestore.FieldValue.increment(!won ? 1 : 0),
          losses: admin.firestore.FieldValue.increment(!won ? 0 : 1),
          updatedAt: now,
        },
        {merge: true}
      );

      // Store rating after in the match doc
      if (matchRef) {
        t.update(matchRef, {ratingAfter: newA});
      }
    });

    // Recalculate positions across all rankings
    await _recalculatePositions();
  }
);

async function _recalculatePositions(): Promise<void> {
  const snap = await db
    .collection("rankings")
    .orderBy("points", "desc")
    .get();

  const batch = db.batch();
  snap.docs.forEach((doc, i) => {
    const newPos = i + 1;
    const oldPos = doc.data().position as number | undefined;
    const delta = oldPos != null ? oldPos - newPos : 0;

    batch.update(doc.ref, {
      position: newPos,
      weeklyDelta: admin.firestore.FieldValue.increment(delta),
    });
  });

  await batch.commit();
}

// ────────────────────────────────────────────────────────────────────────────
// Ranking: push when position changes
// ────────────────────────────────────────────────────────────────────────────
export const onRankingUpdated = onDocumentUpdated(
  "rankings/{userId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before.position === after.position) return;

    const userId = event.params.userId;
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken as string | undefined;

    if (!fcmToken) return;

    const moved = after.position < before.position ? "subido" : "bajado";

    await messaging.send({
      token: fcmToken,
      notification: {
        title: `Has ${moved} en el ranking`,
        body: `Ahora ocupas la posición #${after.position}`,
      },
      data: {type: "ranking_change", position: String(after.position)},
    });
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Scheduled: 24h event reminders
// ────────────────────────────────────────────────────────────────────────────
export const eventReminders = onSchedule(
  "every 60 minutes",
  async () => {
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in25h = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    const eventsSnap = await db
      .collection("events")
      .where("startsAt", ">=", in24h)
      .where("startsAt", "<", in25h)
      .get();

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const regsSnap = await eventDoc.ref.collection("registrations").get();
      const uids = regsSnap.docs.map((d) => d.id);

      for (const uid of uids) {
        const userDoc = await db.collection("users").doc(uid).get();
        const token = userDoc.data()?.fcmToken as string | undefined;
        if (!token) continue;

        await messaging.send({
          token,
          notification: {
            title: "Recordatorio de evento",
            body: `"${eventData.title as string}" empieza mañana a las ${_formatTime(
              (eventData.startsAt as admin.firestore.Timestamp).toDate()
            )}`,
          },
          data: {type: "event_reminder", eventId: eventDoc.id},
        });
      }
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Scheduled: 2h training reminders
// ────────────────────────────────────────────────────────────────────────────
export const trainingReminders = onSchedule(
  "every 30 minutes",
  async () => {
    const now = new Date();
    const in2h = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const in2h30 = new Date(now.getTime() + 2.5 * 60 * 60 * 1000);

    const sessionsSnap = await db
      .collection("trainings")
      .where("startsAt", ">=", in2h)
      .where("startsAt", "<", in2h30)
      .get();

    for (const sessionDoc of sessionsSnap.docs) {
      const sessionData = sessionDoc.data();
      const attendeesSnap = await sessionDoc.ref
        .collection("attendees")
        .get();
      const uids = attendeesSnap.docs.map((d) => d.id);

      for (const uid of uids) {
        const userDoc = await db.collection("users").doc(uid).get();
        const token = userDoc.data()?.fcmToken as string | undefined;
        if (!token) continue;

        await messaging.send({
          token,
          notification: {
            title: "Entrenamiento en 2 horas",
            body: `"${sessionData.title as string}" en ${sessionData.place as string}`,
          },
          data: {type: "training_reminder", sessionId: sessionDoc.id},
        });
      }
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Events: push when event is updated/cancelled
// ────────────────────────────────────────────────────────────────────────────
export const onEventUpdated = onDocumentUpdated(
  "events/{eventId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const scheduleChanged =
      before.startsAt?.seconds !== after.startsAt?.seconds;
    const cancelled =
      !before.cancelled && after.cancelled;

    if (!scheduleChanged && !cancelled) return;

    const eventId = event.params.eventId;
    const regsSnap = await db
      .collection("events")
      .doc(eventId)
      .collection("registrations")
      .get();

    const uids = regsSnap.docs.map((d) => d.id);

    for (const uid of uids) {
      const userDoc = await db.collection("users").doc(uid).get();
      const token = userDoc.data()?.fcmToken as string | undefined;
      if (!token) continue;

      const title = cancelled
        ? "Evento cancelado"
        : "Cambio de horario";
      const body = cancelled
        ? `El evento "${after.title as string}" ha sido cancelado`
        : `El evento "${after.title as string}" ha cambiado de horario`;

      await messaging.send({
        token,
        notification: {title, body},
        data: {type: cancelled ? "event_cancelled" : "event_rescheduled", eventId},
      });
    }
  }
);

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────
function _formatTime(date: Date): string {
  return date.toLocaleTimeString("es-ES", {
    hour: "2-digit",
    minute: "2-digit",
  });
}
