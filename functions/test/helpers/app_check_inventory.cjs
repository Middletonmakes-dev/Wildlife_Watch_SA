// Fresh-process inspection: preserve the real SDK constructor and capture only
// its explicit options, which SDK 7.4 does not include in deployment metadata.
const assert = require('node:assert/strict');
const sdk = require('firebase-functions/v2/https');
const realOnCall = sdk.onCall;
const registrations = new Map();
sdk.onCall = (options, handler) => {
  const callable = realOnCall(options, handler);
  assert(!registrations.has(callable), 'duplicate callable registration');
  registrations.set(callable, options);
  return callable;
};

const exportsToCheck = {...require('../../lib/index')};
if (process.argv.includes('--unenforced-fixture')) {
  exportsToCheck.unenforcedFixture = sdk.onCall({enforceAppCheck: false}, () => null);
}
const expected = process.env.FUNCTIONS_EMULATOR !== 'true';
const entries = Object.entries(exportsToCheck);
assert(entries.length > 0, 'callable inventory must not be empty');
assert.equal(entries.length, registrations.size, 'every registration must be exported');
for (const [name, callable] of entries) {
  // This module exports only callables. Fail rather than silently skip an
  // export with missing/changed metadata, including an empty callableTrigger.
  assert(Object.hasOwn(callable.__endpoint ?? {}, 'callableTrigger'), `${name}: callable metadata missing`);
  assert(registrations.has(callable), `${name}: registration missing`);
  assert.equal(registrations.get(callable).enforceAppCheck, expected, `${name}: enforceAppCheck`);
}
console.log(JSON.stringify({emulator: process.env.FUNCTIONS_EMULATOR ?? null,
  enforceAppCheck: expected, callables: entries.map(([name]) => name).sort()}));
