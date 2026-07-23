const fs = require('fs');
const path = require('path');

function generateHtmlReport(results, outputPath) {
  const total = results.length;
  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  const skipped = total - passed - failed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';
  const totalDuration = results.reduce((s, r) => s + (r.duration || 0), 0);

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
<title>Appium E2E Frontend Testing — Execution Report</title>
<style>
  :root { --bg: #0b0f19; --card: #151d30; --border: #233252; --text: #d0d6e2; --accent: #4382ff; --green: #2ecc71; --red: #e74c3c; --yellow: #f1c40f; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; }
  h1 { color: #ffffff; margin-bottom: .5rem; font-size: 2rem; font-weight: 600; }
  h2 { color: var(--accent); margin: 2rem 0 1rem; font-size: 1.4rem; border-bottom: 2px solid var(--border); padding-bottom: .5rem; }
  .meta { color: #7f8fa4; margin-bottom: 2rem; font-size: .95rem; }
  .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 1.5rem; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
  .card .value { font-size: 2.2rem; font-weight: 700; }
  .card .label { font-size: .85rem; color: #7f8fa4; margin-top: .4rem; text-transform: uppercase; letter-spacing: 0.5px; }
  .card.pass .value { color: var(--green); }
  .card.fail .value { color: var(--red); }
  .card.skip .value { color: var(--yellow); }
  .card.rate .value { color: var(--accent); }
  table { width: 100%; border-collapse: collapse; margin-bottom: 2.5rem; font-size: .9rem; background: var(--card); border-radius: 8px; overflow: hidden; }
  th { background: #1a253d; color: #ffffff; padding: .8rem 1rem; text-align: left; }
  td { padding: .7rem 1rem; border-bottom: 1px solid var(--border); }
  tr:hover { background: #1c2742; }
  .pass { color: var(--green); font-weight: 600; }
  .fail { color: var(--red); font-weight: 600; }
  .skip { color: var(--yellow); font-weight: 600; }
  .error { color: #f39c12; font-size: .8rem; font-family: monospace; word-break: break-all; }
  .bar { height: 10px; border-radius: 5px; background: var(--border); margin-top: 1rem; overflow: hidden; }
  .bar .fill { height: 100%; border-radius: 5px; background: linear-gradient(90deg, var(--green), #27ae60); }
</style>
</head>
<body>
<h1>📱 Appium E2E Frontend Testing — Execution Report</h1>
<p class="meta">Run Date: ${new Date().toLocaleString()} &middot; Total Execution Duration: ${(totalDuration / 1000).toFixed(2)}s</p>

<div class="dashboard">
  <div class="card"><div class="value">${total}</div><div class="label">Total Tests</div></div>
  <div class="card pass"><div class="value">${passed}</div><div class="label">Passed</div></div>
  <div class="card fail"><div class="value">${failed}</div><div class="label">Failed</div></div>
  <div class="card skip"><div class="value">${skipped}</div><div class="label">Skipped</div></div>
  <div class="card rate"><div class="value">${passRate}%</div><div class="label">Pass Rate</div></div>
</div>
<div class="bar"><div class="fill" style="width:${passRate}%"></div></div>

<h2>📂 Category Summary</h2>
<table>
<tr><th>Category</th><th>Total Tests</th><th>Passed</th><th>Failed</th><th>Skipped</th><th>Pass Rate</th></tr>
${catRows}
</table>

<h2>📋 Test Cases Details</h2>
<table>
<tr><th>#</th><th>Category</th><th>Test Case Name</th><th>Status</th><th>Duration</th><th>Error Message</th></tr>
${testRows}
</table>
</body>
</html>`;

  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(outputPath, html, 'utf-8');
}

module.exports = { generateHtmlReport };
