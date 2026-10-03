const {spawnSync} = require('node:child_process');
const {join} = require('node:path');
for (const test of ['emulator-rules.cjs', 'emulator-callable.cjs']) {
  const result = spawnSync(process.execPath, [join(__dirname, test)], {stdio: 'inherit', env: process.env});
  if (result.status !== 0) process.exit(result.status || 1);
}
