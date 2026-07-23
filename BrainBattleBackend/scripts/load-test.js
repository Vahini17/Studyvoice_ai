/**
 * ═══════════════════════════════════════════════════════════════════════
 *  BrainBattle Backend — k6 Performance Load Test
 *  100 Virtual Users × 1 Minute Baseline Test
 * ═══════════════════════════════════════════════════════════════════════
 */

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 100,
  duration: '1m',
  thresholds: {
    http_req_failed: ['rate<0.05'],        // < 5% request failures
    http_req_duration: ['p(95)<1500'],      // 95th percentile < 1.5s
  },
};

export default function () {
  const BASE = __ENV.BACKEND_URL || 'http://localhost:5000';

  const endpoints = [
    '/api/health',
    '/api/dashboard',
    '/api/users/profile',
    '/api/quiz/categories',
    '/api/progress/stats',
  ];

  const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
  const res = http.get(`${BASE}${endpoint}`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 1500ms': (r) => r.timings.duration < 1500,
    'response body is not empty': (r) => r.body && r.body.length > 0,
  });

  sleep(Math.random() * 0.5 + 0.1);
}
