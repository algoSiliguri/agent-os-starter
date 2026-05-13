#!/usr/bin/env bash
# Smoke test — verifies setup is complete without mutating any state.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" &>/dev/null; then
    echo "  [ok] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== agent-os-starter smoke test ==="
echo ""

# Runtime deps
check "node 20+" install_state_check_node
check "pi CLI available" install_state_check_pi_cli
check "brain CLI available" install_state_check_brain_cli
check "uv available" install_state_check_uv

# Project structure
check ".agent-os/ exists" install_state_check_agent_os_dir
check ".agent-os/contracts/index.json exists" install_state_check_contract_index
check ".agent-os/install-manifest.json exists" install_state_check_manifest_exists
check "install-manifest.json is valid JSON" install_state_check_manifest_json
check "install-manifest.json has required fields" install_state_check_manifest_fields
check "data_store/ exists" install_state_check_data_store_dir

# Brain DB
BRAIN_DB="$(install_state_brain_db_path)"
check "brain DB exists at $BRAIN_DB" install_state_check_brain_db
check "brain CLI can list (DB readable)" install_state_check_brain_list

# Pi extension (best-effort — pi ext list may not exist in all versions)
if install_state_check_pi_cli; then
  check "Agent OS extension registered" install_state_check_agent_os_extension_registered
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo "Run 'bash setup.sh' to fix failures."
  exit 1
fi
echo "All checks passed. Run 'pi', then '/init', '/doctor', and '/flow \"<goal>\"' to start."
