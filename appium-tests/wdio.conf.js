const path = require('path');
const fs = require('fs');
const xlsxReporter = require('./utils/xlsxReporter');
const { generateHtmlReport } = require('./utils/generateHtmlReport');

const RESULTS_FILE = path.join(__dirname, '.wdio-results.jsonl');
const REPORT_DIR = path.join(__dirname, 'reports');

exports.config = {
  runner: 'local',
  port: 4723,
  path: '/',
  specs: [
    path.join(__dirname, 'tests', '*.test.js'),
  ],
  capabilities: [
    {
      platformName: 'Android',
      'appium:deviceName': 'emulator-5554',
      'appium:automationName': 'UiAutomator2',
      'appium:app': process.env.APK_PATH || path.join(__dirname, '..', 'android', 'app', 'build', 'outputs', 'apk', 'debug', 'app-debug.apk'),
      'appium:autoGrantPermissions': true,
      'appium:newCommandTimeout': 300,
      'appium:noReset': false,
    },
  ],
  framework: 'mocha',
  mochaOpts: {
    ui: 'bdd',
    timeout: 300000,
  },
  reporters: ['spec'],
  logLevel: 'warn',
  waitforTimeout: 20000,
  connectionRetryTimeout: 90000,
  connectionRetryCount: 3,

  onPrepare() {
    if (!fs.existsSync(REPORT_DIR)) {
      fs.mkdirSync(REPORT_DIR, { recursive: true });
    }
    if (fs.existsSync(RESULTS_FILE)) {
      fs.unlinkSync(RESULTS_FILE);
    }
    xlsxReporter.startRun();
    console.log('🚀 Appium Test Suite initialized.');
  },

  afterTest(test, context, { error, result, duration, passed }) {
    const row = {
      category: test.parent || 'Appium E2E',
      name: test.title || 'App Test Case',
      status: passed ? 'PASS' : 'FAIL',
      duration: duration || 0,
      error: error ? (error.message || String(error)).slice(0, 500) : '',
    };
    try {
      fs.appendFileSync(RESULTS_FILE, JSON.stringify(row) + '\n');
    } catch (e) {
      console.error('Failed to write test result:', e);
    }
  },

  async onComplete() {
    console.log('📊 Run completed. Parsing results...');
    const lines = fs.existsSync(RESULTS_FILE)
      ? fs.readFileSync(RESULTS_FILE, 'utf-8').split('\n').filter(Boolean)
      : [];

    const testResults = [];
    for (const line of lines) {
      try {
        const row = JSON.parse(line);
        xlsxReporter.recordTest(row);
        testResults.push(row);
      } catch (e) {
        // Skip malformed lines
      }
    }

    const excelPath = path.join(REPORT_DIR, 'appium-test-report.xlsx');
    await xlsxReporter.generateReport(excelPath);
    console.log(`✅ Excel Report generated: ${excelPath}`);

    const htmlPath = path.join(REPORT_DIR, 'execution-report.html');
    generateHtmlReport(testResults, htmlPath);
    console.log(`✅ HTML Report generated: ${htmlPath}`);
  }
};
