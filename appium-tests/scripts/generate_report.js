const path = require('path');
const xlsxReporter = require('../utils/xlsxReporter');
const { generateHtmlReport } = require('../utils/generateHtmlReport');

const CATEGORIES = [
  { name: 'Functional E2E', prefix: 'FUNC', count: 100 },
  { name: 'UI UX Verification', prefix: 'UIUX', count: 100 },
  { name: 'Input Validation', prefix: 'VAL', count: 100 }
];

(async () => {
  console.log('🚀 Simulating 300 Appium test cases...');
  
  xlsxReporter.startRun();
  const testResults = [];

  for (const cat of CATEGORIES) {
    for (let i = 1; i <= cat.count; i++) {
      // 98% pass rate simulation
      const passed = Math.random() > 0.02;
      const duration = Math.floor(Math.random() * 15) + 5; // 5-20ms
      const name = `${cat.prefix}-${String(i).padStart(3, '0')}: Verify scenario details #${i}`;
      const error = passed ? '' : `AssertionError: expected status 200 but received 500 for scenario #${i}`;

      const row = {
        category: cat.name,
        name,
        status: passed ? 'PASS' : 'FAIL',
        duration,
        error
      };

      xlsxReporter.recordTest(row);
      testResults.push(row);
    }
  }

  const reportsDir = path.join(__dirname, '..', 'reports');
  const excelPath = path.join(reportsDir, 'appium-test-report.xlsx');
  const htmlPath = path.join(reportsDir, 'execution-report.html');

  await xlsxReporter.generateReport(excelPath);
  console.log(`✅ Excel Report successfully created: ${excelPath}`);

  generateHtmlReport(testResults, htmlPath);
  console.log(`✅ HTML Report successfully created: ${htmlPath}`);

  console.log('🎉 Generation complete!');
})();
