#!/usr/bin/env node
// Read-only checks. Uses the installed Firebase CLI matcher, not a homemade glob parser.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve, join } from 'node:path';
import { createHash } from 'node:crypto';

const args = process.argv.slice(2);
function option(name, fallback) {
  const index = args.indexOf(name);
  if (index < 0) return fallback;
  assert(args[index + 1] && !args[index + 1].startsWith('--'), `${name} requires a value`);
  return args[index + 1];
}
const configFile = option('--config', 'firebase.goodspotting-links.local.json');
const baseUrl = option('--base-url');
const inventory = args.includes('--inventory');
const appOnly = args.includes('--app-only');
const resourcePolicy = args.includes('--resource-policy');
const cliRoot = option('--firebase-tools-dir', process.env.FIREBASE_TOOLS_DIR ??
  (process.env.APPDATA ? join(process.env.APPDATA, 'npm/node_modules/firebase-tools') : undefined));
const baseline = {
  'x-frame-options': 'DENY',
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'strict-origin-when-cross-origin',
  'permissions-policy': 'geolocation=(self), camera=(self), microphone=(), payment=(), usb=()',
};
const documents = ['/', '/report', '/thanks', '/your-reports', '/map', '/admin', '/support',
  '/report/', '/unrecognised', '/unrecognised/nested', '/__example', '/index.html'];
const assets = [
  ['/main.dart.js', /^(application|text)\/javascript/],
  ['/flutter_bootstrap.js', /^(application|text)\/javascript/],
  ['/service-worker.js', /^(application|text)\/javascript/],
  ['/canvaskit/canvaskit.wasm', /^application\/wasm/],
  ['/icons/icon.svg', /^image\/svg\+xml/],
];
const helpers = ['/__/auth/iframe', '/__/auth/handler'];
const revalidate = ['/', '/index.html', '/main.dart.js', '/flutter_bootstrap.js', '/service-worker.js'];
function assertBaseline(headers, label) {
  for (const [key, value] of Object.entries(baseline)) assert.equal(headers.get(key), value, `${label}: ${key}`);
  const csp = headers.get('content-security-policy') ?? '';
  for (const directive of ["frame-ancestors 'none'", "object-src 'none'", "base-uri 'self'"])
    assert(csp.split(';').map(x => x.trim()).includes(directive), `${label}: ${directive}`);
}
function assertHelper(headers, label) {
  assert(!/deny/i.test(headers.get('x-frame-options') ?? ''), `${label}: helper cannot have XFO DENY`);
  assert(!/frame-ancestors\s+'none'/i.test(headers.get('content-security-policy') ?? ''), `${label}: helper cannot have frame-ancestors none`);
}
function assertResourcePolicy(headers, label) {
  const value = headers.get('content-security-policy-report-only');
  assert(value, `${label}: missing resource report-only policy`);
  const directives = new Map();
  for (const part of value.split(';').map(x => x.trim()).filter(Boolean)) {
    const [name, ...sources] = part.split(/\s+/);
    assert(!directives.has(name), `${label}: duplicate resource directive ${name}`);
    directives.set(name, sources);
    for (const source of sources) {
      assert(!['*', 'https:', 'http:', "'unsafe-eval'"].includes(source) && !source.includes('*'), `${label}: broad resource source ${source}`);
      assert(!["'unsafe-inline'", 'data:', 'blob:'].includes(source) ||
        (source === 'data:' && name === 'img-src') ||
        (source === 'blob:' && ['img-src', 'worker-src'].includes(name)), `${label}: unreviewed resource exception ${name}`);
    }
  }
  for (const name of ['default-src', 'object-src', 'base-uri', 'script-src', 'connect-src', 'img-src', 'style-src', 'font-src', 'worker-src', 'frame-src', 'manifest-src'])
    assert(directives.has(name), `${label}: missing resource directive ${name}`);
  assert.deepEqual(directives.get('default-src'), ["'self'"], `${label}: resource default`);
  assert.deepEqual(directives.get('object-src'), ["'none'"], `${label}: resource objects`);
  assert.deepEqual(directives.get('base-uri'), ["'self'"], `${label}: resource base`);
  assert(directives.get('script-src').some(x => /^'sha256-[A-Za-z0-9+/]{43}='$/.test(x)), `${label}: fixed inline script hash`);
  assert(!directives.has('report-uri') && !directives.has('report-to'), `${label}: remote reporting not authorized`);
}
async function verifyConfig() {
  assert(cliRoot, 'Set FIREBASE_TOOLS_DIR or pass --firebase-tools-dir for the installed Firebase CLI');
  const require = createRequire(resolve(cliRoot, 'package.json'));
  const { configMatcher } = require('./node_modules/superstatic/lib/utils/patterns.js');
  const { hosting } = JSON.parse(await readFile(configFile, 'utf8'));
  assert(hosting && !Array.isArray(hosting), 'Pass one explicitly targeted Hosting configuration');
  const headersFor = path => {
    const result = new Headers();
    for (const rule of hosting.headers ?? []) {
      if (!configMatcher(path, rule)) continue;
      for (const { key, value } of rule.headers) {
        assert(!result.has(key), `${path}: competing ${key} header rules`);
        result.set(key, value);
      }
    }
    return result;
  };
  // The approved source form covers fallback documents without an override on reserved paths.
  for (const source of ['/', '/!(__){,/**}']) {
    const rule = hosting.headers?.find(x => x.source === source && x.headers.some(h => h.key.toLowerCase() === 'content-security-policy'));
    assert(rule, `Missing reviewed application header source ${source}`);
  }
  for (const path of [...documents, ...assets.map(x => x[0])]) {
    assertBaseline(headersFor(path), path);
    if (resourcePolicy) assertResourcePolicy(headersFor(path), path);
  }
  for (const path of [...helpers, '/__/firebase/init.js', '/__/', '/__']) {
    const headers = headersFor(path);
    assertHelper(headers, path);
    for (const key of [...Object.keys(baseline), 'content-security-policy', ...(resourcePolicy ? ['content-security-policy-report-only'] : [])])
      assert(!headers.has(key), `${path}: application header leaks into reserved namespace`);
  }
  for (const path of revalidate) assert.equal(headersFor(path).get('cache-control'), 'no-cache', `${path}: revalidation`);
  if (resourcePolicy) {
    const html = await readFile(resolve(hosting.public, 'index.html'), 'utf8');
    const policy = headersFor('/').get('content-security-policy-report-only');
    for (const [, script] of html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)) {
      if (!script.trim()) continue;
      // HTML parsing normalizes CRLF/CR to LF before CSP hashes script text.
      const hash = `'sha256-${createHash('sha256').update(script.replace(/\r\n?/g, '\n')).digest('base64')}'`;
      assert(policy.includes(hash), 'Configured artifact inline script hash is stale');
    }
    assert.equal(headersFor('/index.html').get('content-security-policy-report-only'), policy, 'Root/other-path resource policies differ');
  }
  const router = await readFile('lib/app/router.dart', 'utf8');
  for (const [, path] of router.matchAll(/path:\s*'([^']+)'/g)) assertBaseline(headersFor(path), `router ${path}`);
  console.log(`PASS local configuration: ${configFile}; ${documents.length} documents, ${assets.length} assets, reserved exclusions and cache`);
}
async function verifyResponses() {
  const base = new URL(baseUrl);
  assert(['https:', 'http:'].includes(base.protocol) && !base.username && !base.password && !base.search && !base.hash && base.pathname === '/', 'Supply a credential-free origin');
  assert(base.protocol === 'https:' || ['localhost', '127.0.0.1', '[::1]'].includes(base.hostname), 'HTTP checks are limited to loopback');
  const expectedResource = resourcePolicy && !inventory
    ? JSON.parse(await readFile(configFile, 'utf8')).hosting.headers
      .find(x => x.source === '/' && x.headers.some(h => h.key.toLowerCase() === 'content-security-policy-report-only'))
      ?.headers.find(h => h.key.toLowerCase() === 'content-security-policy-report-only')?.value
    : null;
  if (resourcePolicy && !inventory) assert(expectedResource, 'Selected config has no expected resource policy');
  const result = [];
  let failures = 0;
  for (const path of [...documents, ...assets.map(x => x[0]), ...(appOnly ? [] : helpers)]) {
    try {
      const response = await fetch(new URL(path, base), { redirect: 'manual', signal: AbortSignal.timeout(15000) });
      const headers = response.headers;
      const item = { path, status: response.status, headers: {} };
      for (const key of ['content-type', 'cache-control', 'strict-transport-security', 'content-security-policy', 'content-security-policy-report-only', ...Object.keys(baseline)])
        if (headers.has(key)) item.headers[key] = headers.get(key);
      result.push(item);
      if (!inventory) {
        if (helpers.includes(path)) {
          assertHelper(headers, path);
          if (resourcePolicy) assert.notEqual(headers.get('content-security-policy-report-only'), expectedResource, `${path}: application resource policy leaks into helper`);
          assert(path.endsWith('handler') ? [200, 400].includes(response.status) : response.status === 200, `${path}: reserved helper status ${response.status}`);
          assert(/^text\/html/.test(headers.get('content-type') ?? ''), `${path}: helper HTML`);
          const text = await response.text();
          assert(!text.includes('flutter_bootstrap.js'), `${path}: helper incorrectly rewrites to app shell`);
        } else {
          assert.equal(response.status, 200, `${path}: status`);
          assertBaseline(headers, path);
          if (resourcePolicy) {
            assertResourcePolicy(headers, path);
            assert.equal(headers.get('content-security-policy-report-only'), expectedResource, `${path}: exact prepared resource policy`);
          }
          const mime = assets.find(x => x[0] === path)?.[1] ?? /^text\/html/;
          assert(mime.test(headers.get('content-type') ?? ''), `${path}: MIME ${headers.get('content-type')}`);
          if (revalidate.includes(path)) assert.equal(headers.get('cache-control'), 'no-cache', `${path}: revalidation`);
        }
        if (base.protocol === 'https:') assert(/max-age=[1-9]\d*/i.test(headers.get('strict-transport-security') ?? ''), `${path}: HSTS`);
      }
      await response.body?.cancel().catch(() => {});
    } catch (error) {
      failures++;
      // Never print URLs/tokens from an exception; only our credential-free path and assertion text.
      console.error(`FAIL ${path}: ${error.code === 'ERR_ASSERTION' ? error.message : error.name}`);
    }
  }
  console.log(JSON.stringify({ origin: base.origin, mode: inventory ? 'inventory only; no readiness claim' : 'required baseline', authHelpers: appOnly ? 'excluded; verification pending' : 'checked', responses: result, failures }, null, 2));
  assert.equal(failures, 0, `${failures} response checks failed`);
}
try {
  if (baseUrl) await verifyResponses();
  else {
    assert(!inventory, '--inventory requires --base-url');
    await verifyConfig();
  }
} catch (error) {
  console.error(error.code === 'ERR_ASSERTION' ? error.message : `Verification failed: ${error.name}`);
  process.exitCode = 1;
}
