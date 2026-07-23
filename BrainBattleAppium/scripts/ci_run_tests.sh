#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  BrainBattle Appium — CI Test Runner
#  Runs inside the GHA Android Emulator Runner container.
# ═══════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "══════════════════════════════════════════════════════════════"
echo "  📱 BrainBattle Appium CI Runner"
echo "══════════════════════════════════════════════════════════════"

# ── 1. Inject GITHUB_PATH into current PATH ────────────────────────────
if [ -f "${GITHUB_PATH:-}" ]; then
  echo "📌 Injecting GITHUB_PATH entries into PATH…"
  while IFS= read -r p; do
    export PATH="$p:$PATH"
  done < "$GITHUB_PATH"
fi
echo "  Node: $(which node) — $(node --version)"
echo "  npm:  $(which npm)  — $(npm --version)"

# ── 2. Install APK onto emulator ────────────────────────────────────────
APK_PATH="${APK_PATH:-$(find "$PROJECT_DIR/../android" -name '*.apk' -path '*/debug/*' 2>/dev/null | head -1)}"
if [ -z "$APK_PATH" ]; then
  echo "❌ No APK found. Set APK_PATH or build the debug APK first."
  exit 1
fi
echo "📦 Installing APK: $APK_PATH"
adb install -r "$APK_PATH"
echo "  ✅ APK installed."

# ── 3. Start Appium server ──────────────────────────────────────────────
echo "🚀 Starting Appium server…"
npx appium --log-level warn > /tmp/appium.log 2>&1 &
APPIUM_PID=$!

# Wait for Appium to respond on port 4723
MAX_RETRIES=30
RETRY=0
until curl -sf http://localhost:4723/status > /dev/null 2>&1; do
  RETRY=$((RETRY + 1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "❌ Appium failed to start after ${MAX_RETRIES} retries."
    cat /tmp/appium.log || true
    exit 1
  fi
  echo "  ⏳ Waiting for Appium… (attempt $RETRY/$MAX_RETRIES)"
  sleep 2
done
echo "  ✅ Appium is running on port 4723 (PID: $APPIUM_PID)"

# ── 4. Run WebDriverIO ──────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  🧪 Running WDIO Tests"
echo "══════════════════════════════════════════════════════════════"

WDIO_EXIT=0
node node_modules/@wdio/cli/bin/wdio.js run wdio.conf.js || WDIO_EXIT=$?

# ── 5. Handle failures — generate fallback report ──────────────────────
if [ "$WDIO_EXIT" -ne 0 ]; then
  echo ""
  echo "⚠️  WDIO exited with code $WDIO_EXIT — generating fallback report…"
  node utils/generateFallbackReport.js "WDIO exited with code $WDIO_EXIT" || true
fi

# ── 6. Cleanup ──────────────────────────────────────────────────────────
echo ""
echo "🧹 Stopping Appium server…"
kill "$APPIUM_PID" 2>/dev/null || true

echo "══════════════════════════════════════════════════════════════"
echo "  🏁 CI Run Complete (exit code: $WDIO_EXIT)"
echo "══════════════════════════════════════════════════════════════"

exit "$WDIO_EXIT"
