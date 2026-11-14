#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
: "${CAPTURE_URL:?Set CAPTURE_URL to the exact preview URL.}"
: "${CAPTURE_DIR:?Set CAPTURE_DIR to the evidence output directory.}"
mkdir -p "$CAPTURE_DIR"

echo '[timing] browser capture workflow'
/usr/bin/time -p node --input-type=module <<'NODE'
import { mkdirSync, readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join } from 'node:path';
import { performance } from 'node:perf_hooks';

const timed = async (label, task) => {
  const start = performance.now();
  try { return await task(); }
  finally { console.log(`[timing] ${label}: ${Math.round(performance.now() - start)} ms`); }
};
const transient = error => Object.assign(error, { exitCode: 75 });
const runtime = join(process.env.HOME, '.local/share/omgithub-playwright');
const require = createRequire(join(runtime, 'package.json'));
const { chromium } = require('playwright');
const configPath = join(runtime, process.platform === 'darwin' ? 'metal.json' : 'linux.json');
const config = JSON.parse(readFileSync(configPath, 'utf8'));
if (process.platform === 'linux') process.env.DISPLAY ||= ':' + readFileSync(join(runtime, 'display'), 'utf8').trim();
const url = process.env.CAPTURE_URL;
const output = process.env.CAPTURE_DIR;
mkdirSync(output, { recursive: true });
let browser;
try {
  browser = await timed('browser launch', () => chromium.launch({ ...config.browser.launchOptions, timeout: 30000 }).catch(transient));
  for (const view of [
    { name: 'desktop', width: 1440, height: 900, isMobile: false, hasTouch: false },
    { name: 'mobile', width: 700, height: 390, isMobile: true, hasTouch: true },
  ]) {
    const page = await timed(`${view.name} page creation`, () => browser.newPage({ viewport: { width: view.width, height: view.height }, isMobile: view.isMobile, hasTouch: view.hasTouch }).catch(transient));
    page.setDefaultTimeout(30000);
    const pageErrors = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    let response;
    try {
      response = await timed(`${view.name} navigation`, () => page.goto(url, { waitUntil: 'load', timeout: 45000 }).catch(transient));
    } catch (error) { await page.close().catch(() => {}); throw error; }
    if (!response?.ok()) {
      await page.close().catch(() => {});
      const status = response?.status();
      const retryable = !response || [408, 425, 429, 500, 502, 503, 504].includes(status);
      throw Object.assign(new Error(`Preview navigation returned HTTP ${status ?? 'no response'} (${url})`), { exitCode: retryable ? 75 : 1 });
    }
    try {
      await timed(`${view.name} app render wait`, () => page.waitForFunction(() => {
        const canvas = document.querySelector('#game');
        const ui = document.querySelector('#ui');
        const menu = ui?.innerText?.includes('ENTER THE ARENA');
        return !!canvas && canvas.width > 0 && canvas.height > 0 && !!menu && canvas.getBoundingClientRect().width > 0 && canvas.getBoundingClientRect().height > 0;
      }, { timeout: 30000 }));
      if (view.isMobile) {
        await timed('mobile enter arena', () => page.locator('#start').click());
        await timed('mobile controls render wait', () => page.locator('.mobile-controls .touch-btn').first().waitFor({ state: 'visible' }));
      }
      await timed(`${view.name} visual settle`, () => page.waitForTimeout(1200));
      if (pageErrors.length) throw new Error(`Application runtime error: ${pageErrors.join('; ')}`);
      await timed(`${view.name} screenshot`, () => page.screenshot({ path: join(output, `final-${view.name}.png`), timeout: 30000 }).catch(error => {
        if (error.name === 'TimeoutError' || !browser.isConnected()) throw transient(error);
        throw error;
      }));
      console.log(`Captured ${view.name}: ${view.width}x${view.height}`);
    } finally { await timed(`${view.name} page close`, () => page.close()); }
  }
} catch (error) {
  console.error(error);
  process.exitCode = error.exitCode || 1;
} finally {
  if (browser) await timed('browser close', () => browser.close().catch(error => { console.error(error); process.exitCode ||= 75; }));
}
NODE
