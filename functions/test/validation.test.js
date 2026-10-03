const test = require('node:test');
const assert = require('node:assert/strict');
const {validateSubmission} = require('../lib/validation');

test('rejects non-ISO and future occurrence timestamps', () => {
  const valid = {requestId: 'date', latitude: 0, longitude: 0, incidentType: 'injured', locationSource: 'manual_pin'};
  assert.ok(validateSubmission({...valid, occurredAt: 'October 3 2026'}).length);
  assert.ok(validateSubmission({...valid, occurredAt: '2999-10-03T00:00:00.000Z'}).length);
});

test('accepts a finite report with an allowed incident type', () => {
  assert.deepEqual(validateSubmission({
    requestId: 'request-1',
    latitude: -34.126,
    longitude: 18.375,
    incidentType: 'injured',
    locationSource: 'device_gps',
    note: 'Near the verge',
  }), []);
});

test('rejects forged fields, invalid numbers, and unsupported types', () => {
  const errors = validateSubmission({
    requestId: 'request-1',
    latitude: NaN,
    longitude: 181,
    incidentType: 'not-a-type',
    locationSource: 'device_gps',
    reporterUid: 'forged',
  });

  assert.ok(errors.some((error) => error.includes('latitude')));
  assert.ok(errors.some((error) => error.includes('longitude')));
  assert.ok(errors.some((error) => error.includes('incident type')));
  assert.ok(errors.some((error) => error.includes('unsupported field')));
});
