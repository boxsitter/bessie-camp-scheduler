// Reads the old Firestore database (and the emails from Firebase Auth) into a
// plain JSON dump. Needs `firebase-admin` and a service-account key with read access.

/** Firestore Timestamps -> ISO strings; everything else unchanged. */
export function serialize(value) {
  if (value === null || typeof value !== 'object') return value;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(serialize);
  return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, serialize(v)]));
}

export async function extract({ serviceAccount, log = console.log }) {
  const { initializeApp, cert } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  const { getAuth } = await import('firebase-admin/auth');
  const { readFile } = await import('node:fs/promises');

  const app = initializeApp({ credential: cert(JSON.parse(await readFile(serviceAccount, 'utf8'))) });
  const db = getFirestore(app);
  const documents = [];

  // listDocuments() also yields "missing" parents that only exist because they
  // have subcollections, so nothing is skipped.
  async function walk(collection) {
    for (const ref of await collection.listDocuments()) {
      const snapshot = await ref.get();
      if (snapshot.exists) documents.push({ path: ref.path, data: serialize(snapshot.data()) });
      for (const sub of await ref.listCollections()) await walk(sub);
    }
  }
  for (const collection of await db.listCollections()) {
    log(`Reading ${collection.id}...`);
    await walk(collection);
  }

  const authUsers = [];
  for (const { data } of documents.filter((d) => d.path.startsWith('core_user/'))) {
    try {
      const user = await getAuth(app).getUser(data.firebaseUid);
      authUsers.push({ uid: user.uid, email: user.email ?? null });
    } catch (error) {
      log(`Could not read Firebase Auth user ${data.firebaseUid}: ${error.message}`);
    }
  }

  log(`Read ${documents.length} documents and ${authUsers.length} auth users.`);
  return { exportedAt: new Date().toISOString(), documents, authUsers };
}
