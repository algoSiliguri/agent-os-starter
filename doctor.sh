#!/usr/bin/env bash
# Non-mutating lifecycle doctor for a normal user install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

if [[ "${1:-}" == "--release-check" ]]; then
  exec bash "$REPO_ROOT/release-check.sh"
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: bash doctor.sh [--release-check]

Checks Pi, Agent OS registration, knowledge-brain, project state, and the
install manifest without mutating the user/global install.
EOF
  exit 0
fi

PASS=0
FAIL=0
WARN=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
warn() { echo "  [!] $1"; WARN=$((WARN + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== agent-os-starter doctor ==="
echo ""
echo "Project: $REPO_ROOT"
echo "Lifecycle config: $(install_state_config_path)"
echo "Pi agent dir: $(install_state_pi_agent_dir)"
echo "Expected Agent OS: $(install_state_agent_os_source) ($(install_state_agent_os_expected_version), $(install_state_agent_os_channel))"
echo "Expected knowledge-brain: $(install_state_knowledge_brain_source) ($(install_state_knowledge_brain_expected_version))"
echo ""

if install_state_check_pi_cli; then
  pass "pi CLI found: $(command -v pi)"
  echo "  pi version: $(install_state_pi_version || true)"
else
  fail "pi CLI not found"
  echo "       Repair: npm install -g @earendil-works/pi-coding-agent"
fi

if install_state_check_pi_cli; then
  echo ""
  echo "Pi packages:"
  install_state_pi_list | sed 's/^/  /'
  if install_state_check_agent_os_extension_registered; then
    pass "Agent OS is registered in Pi"
    RESOLVED="$(install_state_agent_os_resolved_path)"
    ACTUAL_SOURCE="$(install_state_agent_os_actual_source)"
    ACTUAL_VERSION="$(install_state_agent_os_actual_version)"
    echo "  actual source: $ACTUAL_SOURCE"
    echo "  actual version: $ACTUAL_VERSION"
    if [[ -n "$RESOLVED" ]]; then
      echo "  resolved path: $RESOLVED"
    else
      warn "Agent OS resolved path not reported by pi list"
    fi
    if [[ "$ACTUAL_SOURCE" == "unknown" ]]; then
      warn "Agent OS source unknown; install manifest missing or incomplete"
      echo "       Repair: bash update.sh --dry-run, then bash update.sh"
    elif [[ "$ACTUAL_SOURCE" != "$(install_state_agent_os_source)" ]]; then
      warn "Agent OS installed from unexpected source"
      echo "       Expected: $(install_state_agent_os_source)"
      echo "       Actual:   $ACTUAL_SOURCE"
      echo "       Repair: bash update.sh --dry-run, then bash update.sh"
    fi
    if [[ "$ACTUAL_VERSION" != "unknown" && "$ACTUAL_VERSION" != "$(install_state_agent_os_expected_version)" ]]; then
      warn "Agent OS version is stale or unexpected: $ACTUAL_VERSION"
      echo "       Expected: $(install_state_agent_os_expected_version)"
      echo "       Repair: bash update.sh --dry-run, then bash update.sh"
    fi
  else
    fail "Agent OS is not registered in Pi"
    echo "       Repair: bash setup.sh"
  fi
fi

echo ""
if install_state_check_brain_cli; then
  pass "brain CLI found: $(install_state_brain_path)"
  if BRAIN_VERSION="$(install_state_brain_version)"; then
    pass "brain version: $BRAIN_VERSION"
    if [[ "$(install_state_knowledge_brain_expected_version)" != "unknown" && "$BRAIN_VERSION" != *"$(install_state_knowledge_brain_expected_version)"* ]]; then
      warn "brain version is stale or unexpected"
      echo "       Expected: $(install_state_knowledge_brain_expected_version)"
      echo "       Actual:   $BRAIN_VERSION"
      echo "       Repair: uv tool install --from \"$(install_state_knowledge_brain_source)\" knowledge-brain --reinstall"
    fi
  else
    warn "brain --version failed: $BRAIN_VERSION"
    echo "       Repair: uv tool install --from \"$(install_state_knowledge_brain_source)\" knowledge-brain --reinstall"
  fi
else
  fail "brain CLI not found"
  echo "       Repair: uv tool install --from \"$(install_state_knowledge_brain_source)\" knowledge-brain --reinstall"
fi

BRAIN_DB="$(install_state_brain_db_path)"
echo "Brain DB path: $BRAIN_DB"
if install_state_check_brain_db; then
  pass "brain DB exists"
else
  warn "brain DB missing"
  echo "       Repair: brain --db-path \"$BRAIN_DB\" init"
fi

echo ""
if install_state_check_agent_os_dir; then
  pass ".agent-os directory exists"
else
  fail ".agent-os directory missing"
  echo "       Repair: open Pi here and run /init"
fi

if install_state_check_manifest_exists; then
  pass "install manifest exists"
  if install_state_check_manifest_json && install_state_check_manifest_fields; then
    pass "install manifest has required lifecycle fields"
    if install_state_check_manifest_schema; then
      pass "install manifest schema matches $(install_state_manifest_schema_version)"
    else
      warn "install manifest schema does not match $(install_state_manifest_schema_version)"
      echo "       Repair: bash update.sh --dry-run, then bash update.sh"
    fi
  else
    warn "install manifest is missing fields or invalid JSON"
    echo "       Repair: bash update.sh --dry-run, then bash update.sh"
  fi
else
  warn "install manifest missing"
  echo "       Repair: bash setup.sh"
fi

if [[ -d "$REPO_ROOT/.agent-os/runtime" ]]; then
  pass ".agent-os/runtime exists"
else
  warn ".agent-os/runtime missing"
  echo "       Repair: open Pi here and run /init --upgrade"
fi

if [[ -d "$REPO_ROOT/.agent-os/tasks" ]]; then
  pass ".agent-os/tasks exists"
else
  warn ".agent-os/tasks missing"
  echo "       Repair: open Pi here and run /init --upgrade"
fi

echo ""
echo "Results: $PASS passed, $WARN warnings, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
