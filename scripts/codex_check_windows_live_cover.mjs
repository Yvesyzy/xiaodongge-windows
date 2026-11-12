import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { _electron as electron } from 'playwright';

const root = path.resolve(import.meta.dirname, '..');
const require = createRequire(import.meta.url);
const output = path.join(root, 'release', `codex_windows_cover_live_${Date.now()}`);
const profile = path.join(output, 'profile');
const latest = process.argv[2] ? null : JSON.parse(await readFile(path.join(root, 'release', 'codex_windows_latest.json'), 'utf8'));
const executable = path.resolve(process.argv[2] ?? latest.executable);
await mkdir(output, { recursive: true });
const checks = [];
const errors = [];
let application;
let page;
async function launch() {
  application = await electron.launch({ executablePath: executable, args: [`--codex-profile=${profile}`], cwd: root, timeout: 30000 });
  assert.equal(await application.evaluate(({ app }) => app.getPath('userData')), profile);
  page = await application.firstWindow();
  page.setDefaultTimeout(20000);
  page.on('pageerror', error => errors.push(error.message));
  await page.waitForSelector('.desktop-app-shell');
}
async function query(statement) {
  return page.evaluate(async statement => (await window.CapacitorCustomPlatform.plugins.CapacitorSQLite.query({
    database: 'music_feelings_archive', statement, values: [], readonly: false })).values, statement);
}
try {
  await launch();
  const track = await page.evaluate(() => window.CapacitorCustomPlatform.plugins.NowPlaying.getCurrentTrack({ includeArtwork: true }));
  assert.ok(track.title, 'Keep a player with a Windows media session playing');
  assert.match(track.coverDataUrl ?? '', /^data:image\/(png|jpeg|webp|gif|bmp);base64,[A-Za-z0-9+/]+={0,2}$/, 'Player must provide a readable thumbnail for this live check');
  const mime = /^data:image\/(png|jpeg|webp|gif|bmp);/.exec(track.coverDataUrl)[1];
  const imageFile = `codex_actual_player_cover.${mime === 'jpeg' ? 'jpg' : mime}`;
  await writeFile(path.join(output, imageFile), Buffer.from(track.coverDataUrl.split(',')[1], 'base64'));
  const { coverDataUrl: _cover, ...metadata } = track;
  checks.push('Actual player artwork crosses packaged PowerShell, WinRT, main-process enrichment and preload IPC');
  await page.evaluate(() => { location.hash = '/new'; });
  await page.waitForFunction(() => {
    const image = document.querySelector('img.cover-art');
    return image?.complete && image.naturalWidth > 0;
  });
  // Catalog enrichment may change the cover target; wait for the actual read to finish.
  await page.getByRole('button', { name: '读取当前播放', exact: true }).waitFor({ timeout: 30000 });
  const actual = await page.locator('img.cover-art').evaluate(image => ({ src: image.getAttribute('src'),
    width: image.naturalWidth, height: image.naturalHeight }));
  assert.ok(actual.width > 0 && actual.height > 0 && actual.width * actual.height <= 20_000_000);
  const album = await page.locator('input[name="albumName"]').inputValue();
  const song = await page.locator('input[name="songName"]').inputValue();
  const artist = await page.locator('input[name="artistName"]').inputValue();
  assert.equal(song, track.title, 'Song changed during this check; rerun with a stable current song');
  assert.equal(actual.src, track.coverDataUrl);
  assert.equal((await query('SELECT COUNT(*) AS count FROM ReviewEntry'))[0].count, 0);
  await page.screenshot({ path: path.join(output, 'codex_actual_player_full.png'), fullPage: true });
  await page.locator('textarea[name="content"]').fill('codex 本机播放器封面验收。此合成文字只写入隔离测试档案。');
  await page.getByRole('button', { name: '保存正式乐评', exact: true }).click();
  await page.waitForURL(/#\/entries\//);
  const covers = await query('SELECT * FROM CoverImage');
  assert.equal(covers.length, 1);
  assert.equal(covers[0].dataUrl, actual.src);
  checks.push('Live artwork previews at bounded dimensions and persists with the confirmed album in isolated SQLite');
  await application.close();
  application = null;
  await launch();
  assert.equal((await query('SELECT * FROM CoverImage'))[0].dataUrl, actual.src);
  await page.evaluate(() => { location.hash = '/capture'; });
  await page.waitForFunction(expected => {
    const image = document.querySelector('.quick-track-card img');
    return image?.getAttribute('src') === expected && image.complete && image.naturalWidth > 0;
  }, actual.src);
  await page.getByRole('button', { name: '读取当前播放', exact: true }).waitFor({ timeout: 30000 });
  assert.equal(await page.getByLabel('专辑', { exact: true }).inputValue(), album);
  assert.equal(await page.getByLabel('歌手', { exact: true }).inputValue(), artist);
  await page.screenshot({ path: path.join(output, 'codex_actual_player_quick.png'), fullPage: true });
  checks.push('Restart preserves the live cover and quick capture resolves the same album artwork');
  assert.deepEqual(errors, []);
  const result = { status: 'passed', checkedAt: new Date().toISOString(), executable, isolatedProfile: profile,
    scope: 'Actual Windows player; isolated archive only; no playback control or player setting changes',
    track: metadata, album, artist, image: { format: mime, file: imageFile, width: actual.width, height: actual.height,
      bytes: Buffer.from(actual.src.split(',')[1], 'base64').length }, checks, pageErrors: errors };
  await writeFile(path.join(output, 'codex_windows_live_cover_checks.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify({ status: result.status, output, title: track.title, album, source: metadata.musicMetadata?.sourcePackage,
    image: result.image, checks: checks.length }));
} catch (error) {
  if (page) await page.screenshot({ path: path.join(output, 'codex_failure.png'), fullPage: true }).catch(() => undefined);
  await writeFile(path.join(output, 'codex_windows_live_cover_failure.json'), JSON.stringify({ status: 'failed', checks, pageErrors: errors, error: error.stack }, null, 2));
  throw error;
} finally { if (application) await application.close(); }
