import assert from 'node:assert/strict';
import path from 'node:path';
import { _electron as electron } from 'playwright';

const [executablePath, profile, mode] = process.argv.slice(2);
assert.ok(executablePath && profile && ['write', 'read'].includes(mode));
const application = await electron.launch({ executablePath, args: [`--codex-profile=${profile}`], timeout: 30000 });
try {
  const page = await application.firstWindow();
  await page.waitForSelector('.desktop-app-shell', { timeout: 30000 });
  assert.equal(await application.evaluate(({ app, BrowserWindow }) => {
    BrowserWindow.getAllWindows()[0].hide();
    return app.getPath('userData');
  }), path.resolve(profile));
  const result = await page.evaluate(async mode => {
    const plugin = window.CapacitorCustomPlatform.plugins.CapacitorSQLite;
    const options = { database: 'music_feelings_archive', readonly: false };
    if (mode === 'write') {
      await plugin.execute({ ...options, statements: "CREATE TABLE codex_installer_check(value TEXT NOT NULL); INSERT INTO codex_installer_check VALUES ('synthetic installer persistence');" });
      localStorage.setItem('codex:installer-check', 'synthetic Chromium persistence');
    }
    return {
      database: (await plugin.query({ ...options, statement: 'SELECT value FROM codex_installer_check', values: [] })).values,
      storage: localStorage.getItem('codex:installer-check'),
    };
  }, mode);
  assert.deepEqual(result, { database: [{ value: 'synthetic installer persistence' }], storage: 'synthetic Chromium persistence' });
  console.log(`INSTALLED_APP_${mode.toUpperCase()}_PASS`);
} finally {
  await application.close();
}
