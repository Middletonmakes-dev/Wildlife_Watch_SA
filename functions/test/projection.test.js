const test = require('node:test');
const assert = require('node:assert/strict');
const {createPublicProjection, haversineMetres, projectionForModeration, publicationEligibility} = require('../lib/projection');

test('publication eligibility uses exactly seven days of trusted creation time', () => {
  const created = new Date('2030-01-01T12:00:00Z');
  const eligibleAt = new Date('2030-01-08T12:00:00Z');
  assert.deepEqual(publicationEligibility(created, new Date(eligibleAt.getTime() - 1)), {eligible: false, eligibleAt});
  assert.deepEqual(publicationEligibility(created, eligibleAt), {eligible: true, eligibleAt});
  assert.throws(() => publicationEligibility(new Date(NaN), eligibleAt));
  assert.throws(() => publicationEligibility(created, new Date(NaN)));
});

test('the new publication radius preserves the public allowlist and stable reacceptance', () => {
  for (const random of [0, 0.999999]) {
    const point = createPublicProjection({id: 'v2', incidentType: 'injured', latitude: -34.197,
      longitude: 18.375, random: () => random, minimumMetres: 100, maximumMetres: 250});
    const distance = haversineMetres(-34.197, 18.375, point.displayLatitude, point.displayLongitude);
    assert.ok(distance >= 99.999 && distance <= 250);
    assert.deepEqual(Object.keys(point).sort(), ['date','displayLatitude','displayLongitude','id','incidentType']);
    assert.equal(projectionForModeration('accepted', point, () => {throw new Error('must stay stable');}), point);
  }
});

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
