const path = require('path');
const fs = require('fs');

// ── Reporting Utilities ──────────────────────────────────────────────
const xlsxReporter = require('./utils/xlsxReporter');
const { generateHtmlReport } = require('./utils/generateHtmlReport');
const { generateSummary } = require('./utils/generateSummary');

const RESULTS_FILE = path.join(__dirname, '.wdio-results.jsonl');
const REPORT_DIR = path.join(__dirname, 'reports');

exports.config = {
  // ── Runner ──────────────────────────────────────────────────────────
  runner: 'local',
  port: 4723,
  path: '/',

  // ── Specs ───────────────────────────────────────────────────────────
  specs: [
    process.env.WDIO_CI_SPEC
      ? path.resolve(__dirname, process.env.WDIO_CI_SPEC)
      : path.join(__dirname, 'tests', '12_e2e', '*.test.js'),
  ],

  // ── Capabilities ────────────────────────────────────────────────────
  capabilities: [
    {
      platformName: 'Android',
      'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
      'appium:platformVersion': process.env.PLATFORM_VERSION || '10',
      'appium:automationName': 'UiAutomator2',
      'appium:app': process.env.APK_PATH || path.join(__dirname, '..', 'android', 'app', 'build', 'outputs', 'apk', 'debug', 'app-debug.apk'),
      'appium:autoGrantPermissions': true,
      'appium:newCommandTimeout': 300,
      'appium:noReset': false,
    },
  ],

  // ── Framework ───────────────────────────────────────────────────────
  framework: 'mocha',
  mochaOpts: {
    ui: 'bdd',
    timeout: 600000, // 10 min — generous for emulator boot
  },

  reporters: ['spec'],
  logLevel: 'warn',
  waitforTimeout: 30000,
  connectionRetryTimeout: 180000,
  connectionRetryCount: 3,

  // ── Hooks ───────────────────────────────────────────────────────────

  onPrepare() {
    // Ensure reports dir exists
    if (!fs.existsSync(REPORT_DIR)) fs.mkdirSync(REPORT_DIR, { recursive: true });
    // Clear previous results
    if (fs.existsSync(RESULTS_FILE)) fs.unlinkSync(RESULTS_FILE);
    // Initialize reporter
    xlsxReporter.startRun();
    console.log('\n🚀 WDIO run initialized — results file cleared.\n');
  },

  afterTest(test, _context, { error, result, duration, passed }) {
    const row = {
      category: test.parent || 'Unknown',
      name: test.title || 'Untitled',
      status: passed ? 'PASS' : 'FAIL',
      duration: duration || 0,
      error: error ? (error.message || String(error)).slice(0, 500) : '',
    };
    try {
      fs.appendFileSync(RESULTS_FILE, JSON.stringify(row) + '\n');
    } catch (_) { /* swallow write errors in sandbox */ }
  },

  after(result, capabilities, specs) {
    // If the session never started (fatal Appium crash), record a fallback row
    if (!fs.existsSync(RESULTS_FILE) || fs.statSync(RESULTS_FILE).size === 0) {
      const fallback = {
        category: 'FATAL',
        name: 'Appium session failed to start',
        status: 'FAIL',
        duration: 0,
        error: 'Appium/WebDriverIO session could not be established.',
      };
      fs.writeFileSync(RESULTS_FILE, JSON.stringify(fallback) + '\n');
    }
  },

  async onComplete() {
    console.log('\n📊 Generating reports…\n');

    // ── Load JSONL results ──
    const lines = fs.existsSync(RESULTS_FILE)
      ? fs.readFileSync(RESULTS_FILE, 'utf-8').split('\n').filter(Boolean)
      : [];

    for (const line of lines) {
      try {
        const row = JSON.parse(line);
        xlsxReporter.recordTest(row);
      } catch (_) { /* skip malformed lines */ }
    }

    // ── Excel ──
    const xlsxPath = path.join(REPORT_DIR, 'appium-test-report.xlsx');
    await xlsxReporter.generateReport(xlsxPath);
    console.log(`  ✅ Excel report → ${xlsxPath}`);

    // ── HTML ──
    const htmlPath = path.join(REPORT_DIR, 'execution-report.html');
    generateHtmlReport(lines.map((l) => JSON.parse(l)), htmlPath);
    console.log(`  ✅ HTML report  → ${htmlPath}`);

    // ── GHA Summary ──
    generateSummary(lines.map((l) => JSON.parse(l)));
    console.log('  ✅ GHA step summary appended (if running in Actions).');

    console.log('\n🏁 All reports generated.\n');
  },
};
