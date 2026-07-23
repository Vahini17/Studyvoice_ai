/**
 * ═══════════════════════════════════════════════════════════════════════
 *  BrainBattle Appium — Fallback Report Generator
 *  Invoked when WDIO/Appium crashes before producing results.
 *  Writes a minimal Excel marking all 1,111 tests as FAIL.
 * ═══════════════════════════════════════════════════════════════════════
 */

const path = require('path');
const xlsxReporter = require('./xlsxReporter');
const { generateHtmlReport } = require('./generateHtmlReport');
const { generateSummary } = require('./generateSummary');

const CATEGORIES = [
  'Functional', 'UI/UX', 'Compatibility', 'Performance', 'Security',
  'API', 'Database', 'Accessibility', 'Mobile-Specific', 'Regression', 'E2E',
];
const TESTS_PER_CAT = 101;

(async () => {
  const REPORT_DIR = path.join(__dirname, '..', 'reports');
  const fs = require('fs');
  if (!fs.existsSync(REPORT_DIR)) fs.mkdirSync(REPORT_DIR, { recursive: true });

  const errorMsg = process.argv[2] || 'Appium/WDIO session failed — fallback report';

  xlsxReporter.startRun();

  const allResults = [];
  for (const cat of CATEGORIES) {
    for (let i = 0; i < TESTS_PER_CAT; i++) {
      const row = {
        category: `[${cat}] Mobile Test Suite`,
        name: i === 0
          ? `${cat.toUpperCase()}-000: Appium driver check`
          : `${cat.toUpperCase().replace(/[^A-Z]/g, '').slice(0, 5)}-${String(i).padStart(3, '0')}: Test #${i}`,
        status: 'FAIL',
        duration: Math.floor(Math.random() * 16) + 5,
        error: errorMsg,
      };
      xlsxReporter.recordTest(row);
      allResults.push(row);
    }
  }

  const xlsxPath = path.join(REPORT_DIR, 'appium-test-report.xlsx');
  await xlsxReporter.generateReport(xlsxPath);
  console.log(`  ✅ Fallback Excel → ${xlsxPath}`);

  const htmlPath = path.join(REPORT_DIR, 'execution-report.html');
  generateHtmlReport(allResults, htmlPath);
  console.log(`  ✅ Fallback HTML  → ${htmlPath}`);

  generateSummary(allResults);
  console.log('  ✅ Fallback summary generated.');
})();
