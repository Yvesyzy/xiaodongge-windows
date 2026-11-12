import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { _electron as electron } from 'playwright';

const root = path.resolve(import.meta.dirname, '..');
const require = createRequire(import.meta.url);
const output = path.join(root, 'release', `codex_windows_cover_ui_${Date.now()}`);
const profile = path.join(output, 'profile');
await mkdir(output, { recursive: true });
const executable = process.argv[2] ? path.resolve(process.argv[2]) : require('electron');
const application = await electron.launch({ executablePath: executable,
  args: [...(process.argv[2] ? [] : [root]), `--codex-profile=${profile}`], cwd: root, timeout: 30000 });
const checks = [];
const errors = [];
let page;
const track = (name, cover) => ({ accessEnabled: true, title: `codex 合成歌曲 ${name}`,
  artistName: 'codex 合成艺人', albumName: `codex 合成专辑 ${name}`,
  musicMetadata: { sourcePackage: 'codex.synthetic.player', displayTitle: `codex 合成歌曲 ${name}` },
  ...(cover === undefined ? {} : { coverDataUrl: cover }) });
async function setPlayback(value, delay = 0) {
  await application.evaluate((_electron, state) => {
    globalThis.codexCoverFixture.track = state.value;
    globalThis.codexCoverFixture.delay = state.delay;
  }, { value, delay });
}
async function navigate(route) {
  await page.evaluate(route => { location.hash = route; }, route);
}
async function captureWindow(fileName) {
  const bytes = await application.evaluate(async ({ BrowserWindow }) =>
    (await BrowserWindow.getAllWindows()[0].webContents.capturePage()).toPNG().toString('base64'));
  await writeFile(path.join(output, fileName), Buffer.from(bytes, 'base64'));
}
async function fresh(route = '/new') {
  await navigate('/');
  await page.locator('.desktop-home-page').waitFor();
  await navigate(route);
  await page.locator(route === '/capture' ? '.quick-capture-form' : 'input[name="title"]').waitFor();
}
async function table(name) {
  return page.evaluate(async name => (await window.CapacitorCustomPlatform.plugins.CapacitorSQLite.query({
    database: 'music_feelings_archive', statement: `SELECT * FROM ${name}`, values: [], readonly: false })).values, name);
}
async function waitFullArtwork(expected) {
  await page.waitForFunction(expected => [...document.querySelectorAll('img.cover-art')]
    .some(image => image.getAttribute('src') === expected && image.complete && image.naturalWidth > 0), expected);
}
async function saveFull(content) {
  await page.locator('textarea[name="content"]').fill(content);
  await page.getByRole('button', { name: '保存正式乐评', exact: true }).click();
  await page.waitForURL(/#\/entries\//);
}
async function exportBackup(includeCovers = true) {
  await navigate('/backup');
  await page.getByRole('heading', { name: '备份', exact: true }).waitFor();
  await page.getByLabel('JSON 包含封面', { exact: true }).setChecked(includeCovers);
  await page.getByRole('button', { name: '导出 JSON', exact: true }).click();
  const field = page.locator('section.form-card').filter({ has: page.getByText('导出的 JSON', { exact: true }) }).locator('textarea');
  await field.waitFor();
  await page.waitForFunction(include => {
    const field = [...document.querySelectorAll('section.form-card')]
      .find(section => section.querySelector('strong')?.textContent === '导出的 JSON')?.querySelector('textarea');
    if (!field?.value) return false;
    const data = JSON.parse(field.value);
    return include || data.covers.length === 0;
  }, includeCovers);
  return JSON.parse(await field.inputValue());
}
try {
  assert.equal(await application.evaluate(({ app }) => app.getPath('userData')), profile);
  page = await application.firstWindow();
  page.setDefaultTimeout(15000);
  page.on('pageerror', error => errors.push(error.message));
  page.on('dialog', dialog => { if (dialog.type() !== 'beforeunload') void dialog.accept(); });
  await page.waitForSelector('.desktop-app-shell');
  const native = await page.evaluate(() => window.CapacitorCustomPlatform.plugins.NowPlaying.getCurrentTrack({ includeArtwork: true }));
  assert.equal(native.accessEnabled, true);
  checks.push('Actual packaged IPC and Windows native artwork request returns a valid media result');
  const images = await page.evaluate(() => ['#1b7374', '#d18b42'].map((color, index) => {
    const canvas = document.createElement('canvas'); canvas.width = 960; canvas.height = 640;
    const context = canvas.getContext('2d');
    if (index === 0) {
      const pixels = context.createImageData(canvas.width, canvas.height);
      let state = 123456789;
      for (let offset = 0; offset < pixels.data.length; offset += 4) {
        state ^= state << 13; state ^= state >>> 17; state ^= state << 5;
        pixels.data[offset] = state & 255; pixels.data[offset + 1] = state >>> 8 & 255;
        pixels.data[offset + 2] = state >>> 16 & 255; pixels.data[offset + 3] = 180;
      }
      context.putImageData(pixels, 0, 0);
    } else { context.fillStyle = color; context.fillRect(0, 0, 960, 640); }
    context.fillStyle = '#fff'; context.font = '30px sans-serif'; context.fillText('CODEX SYNTHETIC COVER', 30, 130);
    return canvas.toDataURL('image/png');
  }));
  const [coverA, coverB] = images;
  assert.ok(coverA.length > 1_400_000, 'Verify the former encoded-size cap is removed');
  assert.ok(Buffer.from(coverA.split(',')[1], 'base64').length <= 4 * 1024 * 1024);
  const manualPath = path.join(output, 'codex_manual_cover.png');
  await writeFile(manualPath, Buffer.from(coverB.split(',')[1], 'base64'));
  // The pinned Electron runtime's map was inspected before using this test-only hook.
  // All non-NowPlaying requests still execute the original trusted IPC handler.
  await application.evaluate(({ ipcMain }) => {
    if (!(ipcMain._invokeHandlers instanceof Map)) throw new Error('Electron test hook unavailable');
    const original = ipcMain._invokeHandlers.get('codex:desktop');
    if (typeof original !== 'function') throw new Error('Desktop IPC handler unavailable');
    globalThis.codexCoverFixture = { track: { accessEnabled: true }, delay: 0, reads: [] };
    ipcMain.removeHandler('codex:desktop');
    ipcMain.handle('codex:desktop', async (event, plugin, method, options) => {
      if (plugin === 'NowPlaying' && method === 'getCurrentTrack') {
        const state = globalThis.codexCoverFixture;
        const value = structuredClone(state.track);
        state.reads.push({ includeArtwork: options?.includeArtwork === true, title: value.title ?? null });
        if (state.delay) await new Promise(resolve => setTimeout(resolve, state.delay));
        return value;
      }
      if (plugin === 'NowPlaying' && method === 'searchCatalog') return { country: options.country, results: [] };
      return original(event, plugin, method, options);
    });
  });

  await setPlayback(track('A', coverA));
  await fresh();
  await waitFullArtwork(coverA);
  assert.deepEqual(await page.locator('img.cover-art').evaluate(image => [image.naturalWidth, image.naturalHeight]), [960, 640]);
  assert.equal((await table('ReviewEntry')).length, 0);
  assert.equal((await table('CoverImage')).length, 0);
  const fullRoute = new URL(page.url()).hash.slice(1);
  await page.locator('textarea[name="content"]').fill('codex 自动封面完整乐评草稿');
  await page.getByRole('button', { name: '保存草稿', exact: true }).click();
  await page.waitForURL(/#\/drafts/);
  const drafts = await page.evaluate(() => Object.keys(localStorage).filter(key => key.startsWith('music-feelings-entry-draft:v1:'))
    .map(key => ({ key, value: JSON.parse(localStorage.getItem(key)) })));
  assert.equal(drafts.length, 1);
  assert.equal(drafts[0].value.coverFromPlayback, true);
  assert.equal(drafts[0].value.coverDataUrl, coverA);
  let backup = await exportBackup(false);
  assert.equal(backup.covers.length, 0);
  assert.equal(JSON.parse(backup.drafts[0].raw).coverFromPlayback, undefined);
  assert.equal(JSON.parse(backup.drafts[0].raw).coverDataUrl, null);
  checks.push('Automatic preview writes no formal data; draft carries artwork; no-cover backup removes provenance and image');
  await navigate(fullRoute);
  await waitFullArtwork(coverA);
  await page.reload();
  await waitFullArtwork(coverA);
  await captureWindow('codex_windows_full_auto_cover.png');
  await saveFull('codex 自动封面保存并重开');
  const entryA = (await table('ReviewEntry'))[0];
  assert.equal((await table('CoverImage'))[0].dataUrl, coverA);
  await page.reload();
  const storedOriginal = (await table('CoverImage'))[0].dataUrl;
  assert.equal(storedOriginal, coverA);
  backup = await exportBackup(true);
  assert.equal(backup.covers[0].dataUrl, coverA);
  const originalHash = value => createHash('sha256').update(Buffer.from(value.split(',')[1], 'base64')).digest('hex');
  const rawPreservation = { width: 960, height: 640, format: 'png',
    bytes: Buffer.from(coverA.split(',')[1], 'base64').length,
    inputSha256: originalHash(coverA), sqliteSha256: originalHash(storedOriginal), backupSha256: originalHash(backup.covers[0].dataUrl) };
  assert.equal(rawPreservation.inputSha256, rawPreservation.sqliteSha256);
  assert.equal(rawPreservation.inputSha256, rawPreservation.backupSha256);
  checks.push('Full editor draft reload, SQLite and full backup preserve original artwork bytes');

  await navigate(`/entries/${entryA.id}/edit`);
  await page.getByLabel('选择封面图片', { exact: true }).setInputFiles(manualPath);
  await page.getByText('封面已选择，保存记录后生效', { exact: true }).waitFor();
  await saveFull('codex 手动封面优先');
  const manual = (await table('CoverImage'))[0].dataUrl;
  assert.notEqual(manual, coverA);
  await fresh();
  await waitFullArtwork(manual);
  await saveFull('codex 已有手动封面不能被系统图覆盖');
  assert.equal((await table('CoverImage'))[0].dataUrl, manual);
  await setPlayback({ ...track('A', coverA), albumName: 'ｃｏｄｅｘ 合成专辑 Ａ' });
  await fresh();
  await waitFullArtwork(manual);
  checks.push('Existing manual artwork wins for exact and normalized album identity');
  await page.locator('input[name="albumName"]').fill('codex 手改已读取封面的作品身份');
  await page.waitForFunction(() => document.querySelectorAll('img.cover-art').length === 0);
  checks.push('A stored cover resolved during playback reading is cleared when its music identity changes');

  await setPlayback(track('B', coverB));
  await fresh('/capture');
  await page.waitForFunction(expected => document.querySelector('.quick-track-card img')?.getAttribute('src') === expected, coverB);
  await page.getByLabel('一句话感受', { exact: true }).fill('codex 速记自动封面');
  await captureWindow('codex_windows_quick_auto_cover.png');
  await page.getByRole('button', { name: '保存专辑听感', exact: true }).click();
  await page.waitForURL(/#\/entries\//);
  assert.equal((await table('CoverImage')).find(item => item.albumName === 'codex 合成专辑 B').dataUrl, coverB);
  checks.push('Quick capture preview and formal save use the same album artwork storage');

  for (const [name, candidate] of [['无图', undefined], ['坏图', 'data:image/jpeg;base64,AAAA']]) {
    await setPlayback(track(name, candidate));
    await fresh();
    await page.waitForFunction(name => document.querySelector('input[name="albumName"]')?.value === `codex 合成专辑 ${name}`, name);
    await page.getByRole('button', { name: '读取当前播放', exact: true }).waitFor({ state: 'visible' });
    await saveFull(`codex ${name}仍然保存`);
    assert.equal((await table('CoverImage')).some(item => item.albumName === `codex 合成专辑 ${name}`), false);
  }
  checks.push('Missing and invalid thumbnails still allow formal record save without an artwork row');

  await setPlayback(track('身份', coverA));
  await fresh();
  await waitFullArtwork(coverA);
  await page.locator('input[name="albumName"]').fill('codex 手改身份');
  await page.waitForFunction(() => document.querySelectorAll('img.cover-art').length === 0);
  await saveFull('codex 修改身份不串图');
  assert.equal((await table('CoverImage')).some(item => item.albumName === 'codex 手改身份'), false);
  checks.push('Editing music identity clears playback artwork before draft or formal persistence');

  await setPlayback(track('迟到', coverA), 900);
  await fresh();
  await page.getByLabel('选择封面图片', { exact: true }).setInputFiles(manualPath);
  await page.getByText('封面已选择，保存记录后生效', { exact: true }).waitFor();
  await page.getByRole('button', { name: '读取当前播放', exact: true }).waitFor();
  const selected = await page.locator('img.cover-art').getAttribute('src');
  assert.notEqual(selected, coverA);
  await page.locator('input[name="title"]').fill('codex 手动选图');
  await page.locator('input[name="albumName"]').fill('codex 合成专辑 迟到');
  await page.locator('input[name="artistName"]').fill('codex 合成艺人');
  await saveFull('codex 迟到系统图不覆盖手动选图');
  assert.equal((await table('CoverImage')).find(item => item.albumName === 'codex 合成专辑 迟到').dataUrl, selected);
  checks.push('A delayed media response cannot overwrite a manually selected cover');

  await setPlayback(track('切歌前', coverA));
  await fresh('/capture');
  await page.waitForFunction(expected => document.querySelector('.quick-track-card img')?.getAttribute('src') === expected, coverA);
  const oldQuickRoute = new URL(page.url()).hash.slice(1);
  await page.getByLabel('一句话感受', { exact: true }).fill('codex 切歌前输入保留');
  await setPlayback(track('切歌后', coverB));
  await page.getByRole('button', { name: '读取当前播放', exact: true }).click();
  await page.getByRole('button', { name: '保存并切换', exact: true }).click();
  await page.waitForFunction(expected => document.querySelector('.quick-track-card img')?.getAttribute('src') === expected, coverB);
  assert.equal(await page.getByLabel('专辑', { exact: true }).inputValue(), 'codex 合成专辑 切歌后');
  await navigate('/');
  await page.locator('.desktop-home-page').waitFor();
  await navigate(oldQuickRoute);
  await page.waitForFunction(expected => document.querySelector('.quick-track-card img')?.getAttribute('src') === expected, coverA);
  assert.equal(await page.locator('.quick-capture-form textarea').inputValue(), 'codex 切歌前输入保留');
  checks.push('Switching tracks saves the prior quick draft and restores its own artwork');

  const requests = await application.evaluate(() => globalThis.codexCoverFixture.reads);
  assert.ok(requests.length > 0 && requests.every(request => request.includeArtwork));
  assert.deepEqual(errors, []);
  const result = { status: 'passed', checkedAt: new Date().toISOString(), executable, profile,
    scope: 'Real Electron and SQLite with synthetic playback IPC; actual WinRT image fixtures checked separately',
    nativeObservation: { hasTitle: Boolean(native.title), hasCover: Boolean(native.coverDataUrl) },
    checks, rawPreservation, artworkRequests: requests.length, pageErrors: errors };
  await writeFile(path.join(output, 'codex_windows_cover_checks.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify({ status: result.status, output, checks: checks.length, pageErrors: errors.length }));
} catch (error) {
  if (page) await page.screenshot({ path: path.join(output, 'codex_failure.png'), fullPage: true }).catch(() => undefined);
  await writeFile(path.join(output, 'codex_windows_cover_failure.json'), JSON.stringify({ status: 'failed',
    checks, pageErrors: errors, error: error.stack }, null, 2));
  throw error;
} finally { await application.close(); }
