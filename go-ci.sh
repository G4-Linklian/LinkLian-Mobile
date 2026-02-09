#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-all}" # help | deps | format | analyze | lint | test | sca | secrets | all

# ---------- helpers ----------
step() {
  echo
  echo "==> $1"
  echo "    $2"
}

die() {
  echo
  echo "❌ FAIL at: $1"
  echo "    What it checks: $2"
  if [[ -n "${3:-}" ]]; then
    echo "    Details:"
    echo -e "$3"
  fi
  exit 1
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage:
  ./go-ci.sh [mode]

Modes:
  help      Show this help

  deps      flutter pub get
  format    dart format --set-exit-if-changed .
  analyze   flutter analyze
  lint      alias of analyze (kept for consistency)
  test      flutter test --coverage

  sca       dependency checks (outdated + deps tree + optional pub audit)
  secrets   gitleaks scan (if installed)

  all       deps -> format -> analyze -> test -> sca -> secrets

Examples:
  chmod +x go-ci.sh

  ./go-ci.sh deps
  ./go-ci.sh format
  ./go-ci.sh analyze
  ./go-ci.sh test
  ./go-ci.sh sca
  ./go-ci.sh secrets

  # รวดเดียว
  ./go-ci.sh all

EOF
}

if [[ "${MODE}" == "help" || "${MODE}" == "-h" || "${MODE}" == "--help" ]]; then
  usage
  exit 0
fi

ensure_flutter() {
  need_cmd flutter || die "flutter" "Flutter SDK availability" \
    "Install Flutter and ensure 'flutter' is on PATH. Try: flutter --version"
  flutter --version >/dev/null 2>&1 || die "flutter" "Flutter SDK works" "Run: flutter --version"
}

run_deps() {
  ensure_flutter
  step "deps" "Fetch Flutter dependencies (pub get)."
  flutter pub get || die "flutter pub get" "Dependency resolution" "Run: flutter pub get"
  echo "    ✅ deps OK"
}

run_format() {
  run_deps
  step "format" "Checks Dart formatting (fails if changes needed)."
  dart format --set-exit-if-changed . || die "dart format" "Code formatting" "Fix: dart format ."
  echo "    ✅ format OK"
}

run_analyze() {
  run_deps
  step "analyze" "Runs static analysis (flutter analyze)."
  flutter analyze || die "flutter analyze" "Static analysis / lint" "Fix analyzer issues then rerun"
  echo "    ✅ analyze OK"
}

run_test() {
  run_deps
  step "test" "Runs Flutter unit/widget tests and produces coverage."
  flutter test --coverage || die "flutter test" "Unit/widget tests" "Run: flutter test --coverage"
  if [[ -f "coverage/lcov.info" ]]; then
    echo "    ✅ coverage/lcov.info found"
  else
    echo "    ⚠️ coverage/lcov.info not found (check flutter test --coverage output)"
  fi
}

run_sca() {
  run_deps
  step "sca" "Dependency checks: outdated + deps tree (+ optional pub audit)."

  flutter pub outdated || echo "    ⚠️ flutter pub outdated returned non-zero (informational)"
  flutter pub deps || true

  # Optional: pub audit (available in newer Flutter/Dart)
  if flutter pub audit --help >/dev/null 2>&1; then
    flutter pub audit || die "flutter pub audit" "Vulnerability advisories in dependencies" \
      "Inspect advisories and update dependencies"
    echo "    ✅ pub audit OK"
  else
    echo "    ⚠️ flutter pub audit not available -> skip vuln advisory check"
  fi

  echo "    ✅ SCA checks done"
}

run_secrets() {
  step "secret scan (gitleaks)" "Scans repository for leaked secrets."
  if need_cmd gitleaks; then
    gitleaks detect --redact --no-git || die "gitleaks" \
      "Secrets leaked in working tree" \
      "Install gitleaks then rerun: gitleaks detect --redact --no-git"
    echo "    ✅ gitleaks OK"
  else
    echo "    ⚠️ gitleaks not found -> skip local secret scan (CI will run it)"
  fi
}

case "$MODE" in
  deps)    run_deps ;;
  format)  run_format ;;
  analyze) run_analyze ;;
  lint)    run_analyze ;;
  test)    run_test ;;
  sca)     run_sca ;;
  secrets) run_secrets ;;
  all)
    run_deps
    run_format
    run_analyze
    run_test
    run_sca
    run_secrets
    ;;
  *)
    echo "Unknown mode: $MODE"
    usage
    exit 2
    ;;
esac

echo
echo "✅ All requested checks passed (mode: $MODE)"
