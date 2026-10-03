const test = require('node:test');
const assert = require('node:assert/strict');
const {createPublicProjection, haversineMetres, projectionForModeration} = require('../lib/projection');

test('rejects an invalid configured privacy radius', () => {
  assert.throws(() => createPublicProjection({id: 'bad', incidentType: 'injured', latitude: 0, longitude: 0, minimumMetres: -1, maximumMetres: 50}));
});

test('creates an allowlisted projection at the configured distance', () => {
  const projection = createPublicProjection({
    id: 'incident-1',
    incidentType: 'dead_roadkill',
    latitude: -34.126,
    longitude: 18.375,
    occurredAt: new Date('2026-10-03T08:30:00.000Z'),
    random: () => 0.5,
  });
  const distance = haversineMetres(-34.126, 18.375, projection.displayLatitude, projection.displayLongitude);

  assert.ok(distance >= 20 && distance <= 50);
  assert.deepEqual(Object.keys(projection).sort(), [
    'date', 'displayLatitude', 'displayLongitude', 'id', 'incidentType',
  ]);
  assert.equal(projection.longitude, undefined);
});

test('reuses the same private projection after moderation retraction and reacceptance', () => {
  const first = createPublicProjection({
    id: 'incident-2', incidentType: 'injured', latitude: -34.126, longitude: 18.375,
    random: () => 0.25,
  });
  const retracted = projectionForModeration('rejected', first, () => {
    throw new Error('must not regenerate on retraction');
  });
  const restored = projectionForModeration('accepted', retracted, () => {
    throw new Error('must not regenerate on reacceptance');
  });
  assert.deepEqual(restored, first);
});

test('keeps displaced coordinates within bounds at a pole and dateline', () => {
  const projection = createPublicProjection({
    id: 'incident-edge', incidentType: 'injured', latitude: 90, longitude: 180,
    random: () => 0.5,
  });
  assert.ok(projection.displayLatitude >= -90 && projection.displayLatitude <= 90);
  assert.ok(projection.displayLongitude >= -180 && projection.displayLongitude <= 180);
  const distance = haversineMetres(90, 180, projection.displayLatitude, projection.displayLongitude);
  assert.ok(distance >= 20 && distance <= 50);
});
