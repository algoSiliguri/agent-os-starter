#!/usr/bin/env bash
# Safe uninstall wrapper. Defaults preserve project data and shared brain CLI.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

DRY_RUN=0
REMOVE_PROJECT_STATE=0
REMOVE_BRAIN=0
CONFIRM_PROJECT_STATE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --remove-project-state) REMOVE_PROJECT_STATE=1 ;;
    --yes-i-understand) CONFIRM_PROJECT_STATE=1 ;;
    --remove-brain-if-owned) REMOVE_BRAIN=1 ;;
    --help|-h)
      cat <<'EOF'
Usage: bash uninstall.sh [--dry-run] [--remove-project-state --yes-i-understand] [--remove-brain-if-owned]

Removes Agent OS from the user/global Pi package registry. By default it
preserves .agent-os, data_store, and the shared knowledge-brain tool.

Options:
  --dry-run                    Print actions without changing anything.
  --remove-project-state       Also remove .agent-os after explicit confirmation.
  --yes-i-understand           Required with --remove-project-state.
  --remove-brain-if-owned      Remove knowledge-brain only when manifest says this starter installed it.
EOF
      exit 0
      ;;
    *)
      echo "ERROR: unknown option $1" >&2
      exit 2
      ;;
  esac
  shift
done

AGENT_OS_SOURCE="$(install_state_agent_os_source)"
MANIFEST_PATH="$(install_state_manifest_path)"

echo "=== agent-os-starter uninstall ==="
echo ""
echo "Lifecycle config: $(install_state_config_path)"
echo "Agent OS source: $AGENT_OS_SOURCE"
echo "Agent OS expected version: $(install_state_agent_os_expected_version)"
echo "Pi agent dir: $(install_state_pi_agent_dir)"
echo "Preserve by default: $REPO_ROOT/.agent-os"
echo "Preserve by default: $REPO_ROOT/data_store"
echo "Preserve by default: shared knowledge-brain CLI"
echo ""

if [[ "$REMOVE_PROJECT_STATE" -eq 1 && "$CONFIRM_PROJECT_STATE" -ne 1 ]]; then
  echo "ERROR: --remove-project-state requires --yes-i-understand" >&2
  exit 2
fi

if ! install_state_check_pi_cli; then
  echo "ERROR: pi CLI not found; cannot update Pi package registry." >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: pi uninstall \"$AGENT_OS_SOURCE\""
else
  pi uninstall "$AGENT_OS_SOURCE" || {
    echo "WARNING: pi uninstall did not find $AGENT_OS_SOURCE; current packages:" >&2
    install_state_pi_list >&2
  }
fi

if [[ "$REMOVE_BRAIN" -eq 1 ]]; then
  if [[ -f "$MANIFEST_PATH" ]] && grep -q '"knowledge_brain_source"' "$MANIFEST_PATH"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "DRY RUN: uv tool uninstall knowledge-brain"
    else
      uv tool uninstall knowledge-brain || true
    fi
  else
    echo "Skipping knowledge-brain removal: manifest does not prove starter ownership."
  fi
else
  echo "Preserved knowledge-brain. Use --remove-brain-if-owned to remove it when manifest ownership is present."
fi

if [[ "$REMOVE_PROJECT_STATE" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: remove $REPO_ROOT/.agent-os"
  else
    rm -rf "$REPO_ROOT/.agent-os"
    echo "Removed project state: $REPO_ROOT/.agent-os"
  fi
else
  echo "Preserved project state: $REPO_ROOT/.agent-os"
fi

echo "Preserved project data: $REPO_ROOT/data_store"
echo "Uninstall wrapper complete."
