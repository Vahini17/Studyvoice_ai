/**
 * ═══════════════════════════════════════════════════════════════════════
 *  BrainBattle Appium — Styled Dark-Theme HTML Report Generator
 * ═══════════════════════════════════════════════════════════════════════
 */

const fs = require('fs');
const path = require('path');

function generateHtmlReport(results, outputPath) {
  const total = results.length;
  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  const skipped = total - passed - failed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';
  const totalDuration = results.reduce((s, r) => s + (r.duration || 0), 0);

  // ── Per-category breakdown ──────────────────────────────────────────
  const cats = [...new Set(results.map((r) => r.category))];
  const catRows = cats
    .map((cat) => {
      const cr = results.filter((r) => r.category === cat);
      const cp = cr.filter((r) => r.status === 'PASS').length;
      const cf = cr.filter((r) => r.status === 'FAIL').length;
      const cs = cr.length - cp - cf;
      const rate = cr.length > 0 ? ((cp / cr.length) * 100).toFixed(1) : '0.0';
      return `<tr><td>${cat}</td><td>${cr.length}</td><td class="pass">${cp}</td><td class="fail">${cf}</td><td class="skip">${cs}</td><td>${rate}%</td></tr>`;
    })
    .join('\n');

  // ── Test case rows ──────────────────────────────────────────────────
  const testRows = results
    .map(
      (r, i) =>
        `<tr><td>${i + 1}</td><td>${r.category}</td><td>${r.name}</td><td class="${r.status.toLowerCase()}">${r.status}</td><td>${r.duration}ms</td><td class="error">${r.error || ''}</td></tr>`
    )
    .join('\n');

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>BrainBattle Appium — Execution Report</title>
<style>
  :root { --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #c9d1d9; --accent: #58a6ff; --green: #3fb950; --red: #f85149; --yellow: #d29922; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; }
  h1 { color: var(--accent); margin-bottom: .5rem; font-size: 1.8rem; }
  h2 { color: var(--accent); margin: 2rem 0 1rem; font-size: 1.3rem; border-bottom: 1px solid var(--border); padding-bottom: .4rem; }
  .meta { color: #8b949e; margin-bottom: 2rem; font-size: .9rem; }
  .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 1.2rem; text-align: center; }
  .card .value { font-size: 2rem; font-weight: 700; }
  .card .label { font-size: .8rem; color: #8b949e; margin-top: .3rem; }
  .card.pass .value { color: var(--green); }
  .card.fail .value { color: var(--red); }
  .card.skip .value { color: var(--yellow); }
  .card.rate .value { color: var(--accent); }
  table { width: 100%; border-collapse: collapse; margin-bottom: 2rem; font-size: .85rem; }
  th { background: #21262d; color: var(--accent); padding: .6rem .8rem; text-align: left; position: sticky; top: 0; }
  td { padding: .5rem .8rem; border-bottom: 1px solid var(--border); }
  tr:hover { background: #1c2128; }
  .pass { color: var(--green); font-weight: 600; }
  .fail { color: var(--red); font-weight: 600; }
  .skip { color: var(--yellow); font-weight: 600; }
  .error { color: #f0883e; font-size: .78rem; max-width: 400px; word-break: break-word; }
  .bar { height: 8px; border-radius: 4px; background: var(--border); margin-top: 1rem; overflow: hidden; }
  .bar .fill { height: 100%; border-radius: 4px; background: linear-gradient(90deg, var(--green), #2ea043); }
</style>
</head>
<body>
<h1>📱 BrainBattle Appium — Execution Report</h1>
<p class="meta">Generated: ${new Date().toISOString()} &middot; Total Duration: ${(totalDuration / 1000).toFixed(2)}s</p>

<div class="dashboard">
  <div class="card"><div class="value">${total}</div><div class="label">Total Tests</div></div>
  <div class="card pass"><div class="value">${passed}</div><div class="label">Passed</div></div>
  <div class="card fail"><div class="value">${failed}</div><div class="label">Failed</div></div>
  <div class="card skip"><div class="value">${skipped}</div><div class="label">Skipped</div></div>
  <div class="card rate"><div class="value">${passRate}%</div><div class="label">Pass Rate</div></div>
</div>
<div class="bar"><div class="fill" style="width:${passRate}%"></div></div>

<h2>📂 Category Breakdown</h2>
<table>
<tr><th>Category</th><th>Total</th><th>Passed</th><th>Failed</th><th>Skipped</th><th>Pass Rate</th></tr>
${catRows}
</table>

<h2>📋 All Test Cases</h2>
<table>
<tr><th>#</th><th>Category</th><th>Test Name</th><th>Status</th><th>Duration</th><th>Error</th></tr>
${testRows}
</table>
</body>
</html>`;

  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(outputPath, html, 'utf-8');
}

module.exports = { generateHtmlReport };
