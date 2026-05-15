#!/usr/bin/env bash
# Explicit smoke for the normal user/global install path.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MUTATE_FLAG=0
ACTUAL_UNINSTALL=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --i-understand-this-mutates-user-install) MUTATE_FLAG=1 ;;
    --actually-uninstall-user-agent-os) ACTUAL_UNINSTALL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h)
      cat <<'EOF'
Usage: bash smoke-user-install.sh --i-understand-this-mutates-user-install [--dry-run] [--actually-uninstall-user-agent-os]

This smoke uses the real user/global Pi profile. It runs setup, doctor,
update --dry-run, and uninstall --dry-run. It does not actually uninstall
unless --actually-uninstall-user-agent-os is also passed. --dry-run keeps
setup non-mutating too.
EOF
      exit 0
      ;;
    *)
      echo "ERROR: unknown option $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$MUTATE_FLAG" -ne 1 ]]; then
  echo "ERROR: this smoke touches the user/global Pi install."
  echo "Re-run with: bash smoke-user-install.sh --i-understand-this-mutates-user-install"
  exit 2
fi

echo "=== user/global install smoke ==="
echo "This touches the real user/global Pi install."
echo "Lifecycle config: $REPO_ROOT/agent-os-install.env"
echo ""

FAILED=0
run_step() {
  local name="$1"
  shift
  echo ""
  echo "--- $name ---"
  if "$@"; then
    echo "[ok] $name"
  else
    local status=$?
    echo "[FAIL] $name exited $status"
    FAILED=1
  fi
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  run_step "setup dry-run" bash "$REPO_ROOT/setup.sh" --dry-run
else
  run_step "setup" bash "$REPO_ROOT/setup.sh"
fi
run_step "doctor" bash "$REPO_ROOT/doctor.sh"
run_step "update dry-run" bash "$REPO_ROOT/update.sh" --dry-run
run_step "uninstall dry-run" bash "$REPO_ROOT/uninstall.sh" --dry-run

if [[ "$ACTUAL_UNINSTALL" -eq 1 ]]; then
  run_step "actual uninstall" bash "$REPO_ROOT/uninstall.sh"
else
  echo "Actual uninstall skipped. Pass --actually-uninstall-user-agent-os to remove the Pi package."
fi

exit "$FAILED"
