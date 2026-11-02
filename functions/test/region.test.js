const test = require('node:test');
const assert = require('node:assert/strict');
const {FUNCTIONS_REGION} = require('../lib/config');
const functions = require('../lib/index');

test('all callable Functions are explicitly deployed in Johannesburg', () => {
  assert.equal(FUNCTIONS_REGION, 'africa-south1');
  for (const [name, callable] of Object.entries(functions)) {
    assert(Object.hasOwn(callable.__endpoint ?? {}, 'callableTrigger'), `${name}: expected callable`);
    assert.deepEqual(callable.__endpoint.region, [FUNCTIONS_REGION], name);
  }
});

test('all callables have explicit pilot capacity and timeout limits', () => {
  const expected = {submitIncident: [10, 30], listOwnIncidents: [10, 30],
    withdrawIncident: [10, 30], uploadIncidentPhoto: [2, 60], setIncidentModeration: [5, 30]};
  for (const [name, [concurrency, timeout]] of Object.entries(expected)) {
    const endpoint = functions[name].__endpoint;
    assert.equal(endpoint.minInstances, 0, name);
    assert.equal(endpoint.maxInstances, 2, name);
    assert.equal(endpoint.concurrency, concurrency, name);
    assert.equal(endpoint.timeoutSeconds, timeout, name);
  }
  assert.equal(functions.uploadIncidentPhoto.__endpoint.availableMemoryMb, 256);
});
