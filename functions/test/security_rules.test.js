const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('rules keep exact incidents and private photos behind trusted roles', () => {
  const firestore = fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8');
  const storage = fs.readFileSync(path.join(__dirname, '..', '..', 'storage.rules'), 'utf8');
  assert.match(firestore, /match \/incidents\/\{incidentId\}/);
  assert.match(firestore, /allow read: if isAdmin\(\);/);
  assert.match(firestore, /allow create, update, delete: if false;/);
  assert.match(storage, /allow get: if isAdmin\(\)/);
  assert.match(storage, /allow create, update: if false/);
});
