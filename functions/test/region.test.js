const test = require('node:test');
const assert = require('node:assert/strict');
const {FUNCTIONS_REGION} = require('../lib/config');
const functions = require('../lib/index');

test('all callable Functions are explicitly deployed in Johannesburg', () => {
  assert.equal(FUNCTIONS_REGION, 'africa-south1');
  for (const name of ['submitIncident', 'uploadIncidentPhoto', 'setIncidentModeration']) {
    assert.deepEqual(functions[name].__endpoint.region, [FUNCTIONS_REGION]);
  }
});
