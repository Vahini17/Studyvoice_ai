#!/usr/bin/env node
/**
 * ═══════════════════════════════════════════════════════════════════════
 *  BrainBattle Backend — Defensive k6 Summary Parser
 *  Reads summary.json and writes metrics to GITHUB_STEP_SUMMARY.
 * ═══════════════════════════════════════════════════════════════════════
 */

const fs = require('fs');
const path = require('path');

// ── Defensive metric extractor (handles nested & flat schemas) ────────
function getMetricValue(metricObj, key) {
  if (!metricObj) return 'N/A';
  // Nested: metricObj.values.rate / metricObj.values.avg etc.
  if (metricObj.values && metricObj.values[key] !== undefined) {
    return metricObj.values[key];
  }
  // Flat: metricObj.rate / metricObj.avg etc.
  if (metricObj[key] !== undefined) {
    return metricObj[key];
  }
  return 'N/A';
}

function fmt(val, decimals = 2) {
  if (val === 'N/A' || val === undefined || val === null) return 'N/A';
  return typeof val === 'number' ? val.toFixed(decimals) : String(val);
}

(function main() {
  const summaryPath = path.join(__dirname, '..', 'summary.json');
  if (!fs.existsSync(summaryPath)) {
    console.error('❌ summary.json not found at:', summaryPath);
    process.exit(1);
  }

  let data;
  try {
    data = JSON.parse(fs.readFileSync(summaryPath, 'utf-8'));
  } catch (err) {
    console.error('❌ Failed to parse summary.json:', err.message);
    process.exit(1);
  }

  const metrics = data.metrics || data;

  // ── Extract metrics defensively ──────────────────────────────────
  const httpReqs = metrics.http_reqs || metrics['http_reqs'] || {};
  const httpDuration = metrics.http_req_duration || metrics['http_req_duration'] || {};
  const httpFailed = metrics.http_req_failed || metrics['http_req_failed'] || {};
  const checks = metrics.checks || {};

  const rps = getMetricValue(httpReqs, 'rate');
  const totalReqs = getMetricValue(httpReqs, 'count');
  const avgDuration = getMetricValue(httpDuration, 'avg');
  const minDuration = getMetricValue(httpDuration, 'min');
  const maxDuration = getMetricValue(httpDuration, 'max');
  const p95Duration = getMetricValue(httpDuration, 'p(95)');
  const failRate = getMetricValue(httpFailed, 'rate');
  const checkRate = getMetricValue(checks, 'rate');

  // ── Build Markdown Summary ───────────────────────────────────────
  const md = `## 📈 k6 Load Test — Performance Summary

| Metric | Value |
|--------|-------|
| **Throughput (RPS)** | ${fmt(rps)} req/sec |
| **Total Requests** | ${fmt(totalReqs, 0)} |
| **Avg Response Time** | ${fmt(avgDuration)} ms |
| **Min Response Time** | ${fmt(minDuration)} ms |
| **Max Response Time** | ${fmt(maxDuration)} ms |
| **p95 Response Time** | ${fmt(p95Duration)} ms |
| **Request Failure Rate** | ${fmt(failRate, 4)} |
| **Check Pass Rate** | ${fmt(checkRate, 4)} |

### Configuration
- **Virtual Users**: 100
- **Duration**: 1 minute
- **Thresholds**: p95 < 1500ms, failure rate < 5%
`;

  // ── Write to GITHUB_STEP_SUMMARY or stdout ───────────────────────
  const summaryFile = process.env.GITHUB_STEP_SUMMARY;
  if (summaryFile) {
    try {
      fs.appendFileSync(summaryFile, md + '\n');
      console.log('✅ k6 metrics appended to GITHUB_STEP_SUMMARY');
    } catch (_) {
      console.log(md);
    }
  } else {
    console.log(md);
  }
})();
