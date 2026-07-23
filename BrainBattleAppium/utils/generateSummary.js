/**
 * ═══════════════════════════════════════════════════════════════════════
 *  BrainBattle Appium — GHA Step Summary Generator
 * ═══════════════════════════════════════════════════════════════════════
 */

const fs = require('fs');

function generateSummary(results) {
  const total = results.length;
  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  const skipped = total - passed - failed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';
  const totalDuration = results.reduce((s, r) => s + (r.duration || 0), 0);

  const cats = [...new Set(results.map((r) => r.category))];
  const catTable = cats
    .map((cat) => {
      const cr = results.filter((r) => r.category === cat);
      const cp = cr.filter((r) => r.status === 'PASS').length;
      const cf = cr.filter((r) => r.status === 'FAIL').length;
      const cs = cr.length - cp - cf;
      const rate = cr.length > 0 ? ((cp / cr.length) * 100).toFixed(1) : '0.0';
      return `| ${cat} | ${cr.length} | ${cp} ✅ | ${cf} ❌ | ${cs} ⏭️ | ${rate}% |`;
    })
    .join('\n');

  const md = `## 📱 BrainBattle Appium — Test Summary

| Metric | Value |
|--------|-------|
| **Total Tests** | ${total} |
| **Passed** | ${passed} ✅ |
| **Failed** | ${failed} ❌ |
| **Skipped** | ${skipped} ⏭️ |
| **Pass Rate** | ${passRate}% |
| **Duration** | ${(totalDuration / 1000).toFixed(2)}s |

### 📂 By Category

| Category | Total | Passed | Failed | Skipped | Pass Rate |
|----------|-------|--------|--------|---------|----------|
${catTable}
`;

  // Write to GHA Step Summary if available
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (summaryFile) {
    try {
      fs.appendFileSync(summaryFile, md + '\n');
    } catch (_) {
      console.log(md);
    }
  } else {
    console.log(md);
  }
}

module.exports = { generateSummary };
