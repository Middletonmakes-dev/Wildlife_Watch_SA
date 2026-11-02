const assert = require('node:assert/strict');
const test = require('node:test');
const {spawnSync} = require('node:child_process');
const {join} = require('node:path');

function inspect(emulator, extra = []) {
  const env = {...process.env};
  delete env.FUNCTIONS_EMULATOR;
  if (emulator !== undefined) env.FUNCTIONS_EMULATOR = emulator;
  return spawnSync(process.execPath, [join(__dirname, 'helpers/app_check_inventory.cjs'), ...extra],
    {env, encoding: 'utf8', timeout: 15_000});
}

for (const emulator of [undefined, 'false', 'true']) {
  test(`every exported callable explicitly configures App Check (emulator=${emulator ?? 'absent'})`, () => {
    const result = inspect(emulator);
    assert.equal(result.status, 0, result.stderr);
    const inventory = JSON.parse(result.stdout);
    assert.equal(inventory.enforceAppCheck, emulator !== 'true');
    assert(inventory.callables.length > 0);
  });
}

test('the same inventory rejects an extra unenforced real-SDK callable', () => {
  const result = inspect(undefined, ['--unenforced-fixture']);
  assert.equal(result.status, 1, result.stderr);
  assert.match(result.stderr, /unenforcedFixture: enforceAppCheck/);
});
