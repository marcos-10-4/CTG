// Seed script for Firebase Emulator Suite (uses Admin SDK — bypasses security rules)
// Run: node scripts/seed.js

process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';

const admin = require('firebase-admin');

// Try to init; if already initialised reuse the app
let app;
try {
  app = admin.initializeApp({ projectId: 'demo-ctg-app' });
} catch (_) {
  app = admin.app();
}

const auth = admin.auth(app);
const db = admin.firestore(app);
const FieldValue = admin.firestore.FieldValue;

// ─── Helper ──────────────────────────────────────────────────────────────────
function ts(dateStr) {
  return admin.firestore.Timestamp.fromDate(new Date(dateStr));
}

// ─── Users ────────────────────────────────────────────────────────────────────
const USERS = [
  {
    email: 'admin@ctg.com',
    password: 'ctg1234',
    displayName: 'Carlos Admin',
    profile: { displayName: 'Carlos Admin', role: 'admin', memberSince: '2020-01-01', phone: '+34 600 000 001', level: 3 },
  },
  {
    email: 'coach@ctg.com',
    password: 'ctg1234',
    displayName: 'María García',
    profile: { displayName: 'María García', role: 'entrenador', memberSince: '2021-03-15', phone: '+34 600 000 002', level: 4 },
  },
  {
    email: 'socio@ctg.com',
    password: 'ctg1234',
    displayName: 'Pedro López',
    profile: { displayName: 'Pedro López', role: 'socio', memberSince: '2022-09-01', phone: '+34 600 000 003', level: 2 },
  },
  {
    email: 'ana@ctg.com',
    password: 'ctg1234',
    displayName: 'Ana Martínez',
    profile: { displayName: 'Ana Martínez', role: 'socio', memberSince: '2023-01-20', phone: '+34 600 000 004', level: 2 },
  },
];

async function createUsers() {
  const uids = {};
  for (const u of USERS) {
    let uid;
    try {
      const record = await auth.createUser({
        email: u.email,
        password: u.password,
        displayName: u.displayName,
      });
      uid = record.uid;
      // Set custom claims so Firestore rules work
      await auth.setCustomUserClaims(uid, { role: u.profile.role });
      console.log(`✓ User ${u.email} → ${uid}`);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        const record = await auth.getUserByEmail(u.email);
        uid = record.uid;
        console.log(`↺ User ${u.email} already exists → ${uid}`);
      } else {
        throw e;
      }
    }
    await db.collection('users').doc(uid).set(u.profile);
    uids[u.email] = uid;
  }
  return uids;
}

// ─── Posts ────────────────────────────────────────────────────────────────────
async function seedPosts(uids) {
  const adminUid = uids['admin@ctg.com'];
  const coachUid = uids['coach@ctg.com'];

  const posts = [
    {
      authorId: adminUid, authorName: 'Carlos Admin', authorRole: 'admin',
      title: 'Torneo de Primavera 2026 — ¡Inscríbete ya!',
      body: 'Este año el torneo de primavera contará con categorías sub-18, adultos y veteranos. Las inscripciones abren el 1 de junio. Plazas muy limitadas — solo 32 participantes por categoría.',
      kind: 'tournament', pinned: true, likesCount: 14, commentsCount: 3, mediaUrls: [],
      createdAt: ts('2026-05-18T10:00:00'),
    },
    {
      authorId: adminUid, authorName: 'Carlos Admin', authorRole: 'admin',
      title: 'Nuevas pistas de pádel disponibles',
      body: 'Ya están habilitadas las 2 nuevas pistas de pádel en la zona norte del club. Podéis reservarlas desde la app o en recepción. Horario: 8:00 – 22:00.',
      kind: 'announcement', pinned: false, likesCount: 8, commentsCount: 1, mediaUrls: [],
      createdAt: ts('2026-05-15T09:00:00'),
    },
    {
      authorId: coachUid, authorName: 'María García', authorRole: 'entrenador',
      title: 'Consejos para mejorar tu revés',
      body: 'Uno de los golpes más subestimados es el revés. Esta semana en el entrenamiento grupal vamos a dedicar 30 minutos específicamente a técnica de revés con peloteo de pared. ¡Os espero!',
      kind: 'news', pinned: false, likesCount: 22, commentsCount: 7, mediaUrls: [],
      createdAt: ts('2026-05-12T16:30:00'),
    },
    {
      authorId: adminUid, authorName: 'Carlos Admin', authorRole: 'admin',
      title: 'Resultados Liga Interna — Mayo 2026',
      body: 'Aquí tenéis los resultados completos de la jornada de la liga interna del pasado sábado. El ranking actualizado ya está disponible en la sección de clasificación.',
      kind: 'news', pinned: false, likesCount: 5, commentsCount: 0, mediaUrls: [],
      createdAt: ts('2026-05-11T18:00:00'),
    },
  ];

  for (const p of posts) {
    const ref = await db.collection('posts').add(p);
    console.log(`  Post: ${p.title.slice(0, 40)}... → ${ref.id}`);
  }
}

// ─── Events ───────────────────────────────────────────────────────────────────
async function seedEvents(uids) {
  const coachUid = uids['coach@ctg.com'];

  const events = [
    {
      title: 'Torneo Primavera Individual',
      description: 'Torneo interno por categorías. Formato eliminatorio con cuadro de 16 jugadores por nivel. Se jugará en las pistas 1, 2 y 3.',
      place: 'Pistas 1–3', kind: 'tournament', level: 2, capacity: 32, registeredCount: 18,
      coachId: null, coverUrl: null,
      startsAt: ts('2026-06-07T09:00:00'), endsAt: ts('2026-06-07T18:00:00'),
    },
    {
      title: 'Clínic de Servicio con María García',
      description: 'Sesión intensiva de 2 horas centrada en la mecánica del servicio: grip, lanzamiento, swing y variaciones. Máximo 8 participantes.',
      place: 'Pista 4', kind: 'clinic', level: 2, capacity: 8, registeredCount: 5,
      coachId: coachUid, coverUrl: null,
      startsAt: ts('2026-05-28T11:00:00'), endsAt: ts('2026-05-28T13:00:00'),
    },
    {
      title: 'Sesión Grupal Nivel Intermedio',
      description: 'Entrenamiento grupal semanal para nivel intermedio. Trabajo de patrones tácticos y juego en paralelo.',
      place: 'Pista 2', kind: 'groupSession', level: 2, capacity: 12, registeredCount: 9,
      coachId: coachUid, coverUrl: null,
      startsAt: ts('2026-05-26T18:00:00'), endsAt: ts('2026-05-26T19:30:00'),
    },
  ];

  for (const e of events) {
    const ref = await db.collection('events').add(e);
    console.log(`  Event: ${e.title.slice(0, 40)} → ${ref.id}`);
  }
}

// ─── Trainings ────────────────────────────────────────────────────────────────
async function seedTrainings(uids) {
  const coachUid = uids['coach@ctg.com'];
  const socioUid = uids['socio@ctg.com'];
  const anaUid   = uids['ana@ctg.com'];

  const sessions = [
    {
      coachId: coachUid, title: 'Entrenamiento Individual — Pedro',
      description: 'Sesión de trabajo técnico. Foco en volea y aproximación.',
      place: 'Pista 3', level: 2, capacity: 1, isGroup: false,
      startsAt: ts('2026-05-22T10:00:00'), durationSeconds: 3600, coachNotes: '',
      plan: [
        { type: 'warmup',    durationMins: 10, description: 'Peloteo suave + movilidad' },
        { type: 'drill',     durationMins: 20, description: 'Voleas cruzadas en T' },
        { type: 'drill',     durationMins: 20, description: 'Aproximación + volea de definición' },
        { type: 'matchPlay', durationMins: 10, description: 'Puntos con situación de red' },
      ],
    },
    {
      coachId: coachUid, title: 'Grupal Avanzado',
      description: 'Entrenamiento para nivel avanzado. Trabajo de táctica y patrones de punto.',
      place: 'Pista 1', level: 3, capacity: 6, isGroup: true,
      startsAt: ts('2026-05-23T17:00:00'), durationSeconds: 5400, coachNotes: 'Trabajar contra el reloj en los patrones.',
      plan: [
        { type: 'warmup',    durationMins: 15, description: 'Peloteo + sprint lateral' },
        { type: 'drill',     durationMins: 30, description: 'Patrón saque + derecha cruzada' },
        { type: 'drill',     durationMins: 30, description: 'Defensa de passing' },
        { type: 'matchPlay', durationMins: 15, description: 'Tie-break' },
      ],
    },
  ];

  for (const s of sessions) {
    const ref = await db.collection('trainings').add(s);
    if (s.isGroup) {
      await db.collection('trainings').doc(ref.id).collection('attendees').doc(socioUid).set({ present: true, note: '' });
      await db.collection('trainings').doc(ref.id).collection('attendees').doc(anaUid).set({ present: false, note: 'Avisó con antelación' });
    } else {
      await db.collection('trainings').doc(ref.id).collection('attendees').doc(socioUid).set({ present: false, note: '' });
    }
    console.log(`  Training: ${s.title.slice(0, 40)} → ${ref.id}`);
  }
}

// ─── Rankings ─────────────────────────────────────────────────────────────────
async function seedRankings(uids) {
  const entries = [
    { uid: uids['coach@ctg.com'], points: 1650, wins: 24, losses: 4, position: 1, weeklyDelta: 1, displayName: 'María García' },
    { uid: uids['admin@ctg.com'], points: 1480, wins: 18, losses: 8, position: 2, weeklyDelta: -1, displayName: 'Carlos Admin' },
    { uid: uids['socio@ctg.com'], points: 1310, wins: 10, losses: 12, position: 3, weeklyDelta: 0, displayName: 'Pedro López' },
    { uid: uids['ana@ctg.com'],   points: 1220, wins: 6, losses: 10, position: 4, weeklyDelta: 2, displayName: 'Ana Martínez' },
  ];

  for (const e of entries) {
    await db.collection('rankings').doc(e.uid).set({
      points: e.points, wins: e.wins, losses: e.losses,
      position: e.position, weeklyDelta: e.weeklyDelta, displayName: e.displayName,
      updatedAt: admin.firestore.Timestamp.now(),
    });
  }
  console.log(`  ${entries.length} ranking entries`);
}

// ─── Payments ─────────────────────────────────────────────────────────────────
async function seedPayments(uids) {
  const socioUid = uids['socio@ctg.com'];
  const anaUid   = uids['ana@ctg.com'];

  await db.collection('payments').doc(socioUid).set({
    status: 'paid', dueDate: ts('2026-06-01'), amount: 45.0, displayName: 'Pedro López',
  });
  await db.collection('payments').doc(anaUid).set({
    status: 'pending', dueDate: ts('2026-05-31'), amount: 45.0, displayName: 'Ana Martínez',
  });

  const months = ['2026-04', '2026-03', '2026-02'];
  for (const m of months) {
    await db.collection('payments').doc(socioUid).collection('records').add({
      month: m, amount: 45.0,
      paidAt: ts(`${m}-05`), method: 'domiciliación',
    });
  }
  console.log(`  Payments for 2 users + ${months.length} history records`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('🌱  Seeding Firebase Emulator (demo-ctg-app)...\n');
  try {
    const uids = await createUsers();
    console.log('\n✓  Posts:');     await seedPosts(uids);
    console.log('✓  Events:');     await seedEvents(uids);
    console.log('✓  Trainings:');  await seedTrainings(uids);
    console.log('✓  Rankings:');   await seedRankings(uids);
    console.log('✓  Payments:');   await seedPayments(uids);

    console.log('\n✅  Seed complete!\n');
    console.log('Test accounts:');
    console.log('  admin@ctg.com  / ctg1234  → admin');
    console.log('  coach@ctg.com  / ctg1234  → entrenador');
    console.log('  socio@ctg.com  / ctg1234  → socio');
    console.log('  ana@ctg.com    / ctg1234  → socio\n');
    process.exit(0);
  } catch (e) {
    console.error('\n❌  Seed failed:', e);
    process.exit(1);
  }
}

main();
