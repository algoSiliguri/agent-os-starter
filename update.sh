#!/usr/bin/env bash
# Update Agent OS and knowledge-brain through the normal user install path.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

DRY_RUN=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: bash update.sh [--dry-run]

Updates the user/global Agent OS Pi package and knowledge-brain CLI using the
normal release sources. Project data under .agent-os and data_store is preserved.
EOF
  exit 0
fi
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

AGENT_OS_SOURCE="$(install_state_agent_os_source)"
KB_SOURCE="$(install_state_knowledge_brain_source)"
BRAIN_DB_PATH="$(install_state_brain_db_path)"
export BRAIN_DB_PATH

echo "=== agent-os-starter update ==="
echo ""
echo "Lifecycle config: $(install_state_config_path)"
echo "Agent OS channel: $(install_state_agent_os_channel)"
echo "Agent OS source: $AGENT_OS_SOURCE"
echo "Agent OS expected version: $(install_state_agent_os_expected_version)"
echo "knowledge-brain source: $KB_SOURCE"
echo "knowledge-brain expected version: $(install_state_knowledge_brain_expected_version)"
echo "Pi agent dir: $(install_state_pi_agent_dir)"
echo "Project state preserved: $REPO_ROOT/.agent-os"
echo "Brain DB preserved: $BRAIN_DB_PATH"
echo ""

if ! install_state_check_pi_cli; then
  echo "ERROR: pi CLI not found. Repair: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
fi
if ! install_state_check_uv; then
  echo "ERROR: uv not found. Repair: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  exit 1
fi

echo "Before:"
install_state_pi_list | sed 's/^/  /'
echo "  manifest Agent OS source: $(install_state_agent_os_actual_source)"
echo "  manifest Agent OS version: $(install_state_agent_os_actual_version)"
if install_state_check_brain_cli; then
  echo "  brain: $(install_state_brain_version || true)"
else
  echo "  brain: not found"
fi
echo ""

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: pi update \"$AGENT_OS_SOURCE\""
  echo "DRY RUN: uv tool install --from \"$KB_SOURCE\" knowledge-brain --reinstall"
  echo "DRY RUN: repair .agent-os/install-manifest.json"
  exit 0
fi

pi update "$AGENT_OS_SOURCE"
uv tool install --from "$KB_SOURCE" knowledge-brain --reinstall
if [[ ! -f "$BRAIN_DB_PATH" ]]; then
  brain --db-path "$BRAIN_DB_PATH" init
fi

BRAIN_VERSION="$(install_state_brain_version || true)"
MANIFEST_PATH="$(install_state_write_manifest "${BRAIN_VERSION:-unknown}" "$AGENT_OS_SOURCE" "user-global" "$KB_SOURCE")"

echo ""
echo "After:"
install_state_pi_list | sed 's/^/  /'
echo "  brain: $(install_state_brain_version || true)"
echo "  expected Agent OS version: $(install_state_agent_os_expected_version)"
echo "Install manifest repaired: $MANIFEST_PATH"
echo "Project data preserved."
