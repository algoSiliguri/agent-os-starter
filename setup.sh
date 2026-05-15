#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

DRY_RUN=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: bash setup.sh [--dry-run]

Install knowledge-brain and register Agent OS with the user's Pi profile.
Use --dry-run to print the commands without mutating the user install.
EOF
  exit 0
fi
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

echo "=== agent-os-starter setup ==="
echo ""
echo "Lifecycle config: $(install_state_config_path)"
echo "Agent OS target: $(install_state_agent_os_source)"
echo "Agent OS expected version: $(install_state_agent_os_expected_version)"
echo "Agent OS install channel: $(install_state_agent_os_channel)"
echo "knowledge-brain target: $(install_state_knowledge_brain_source)"
echo "knowledge-brain expected version: $(install_state_knowledge_brain_expected_version)"
echo ""

# Node 20+
if ! install_state_check_node; then
  echo "ERROR: Node 20+ required. Install from https://nodejs.org" >&2
  exit 1
fi
echo "Node $(install_state_node_version): ok"

# Pi coding agent — must be installed before setup can register the extension
if ! install_state_check_pi_cli; then
  echo "" >&2
  echo "ERROR: 'pi' not found. Install Pi first, then re-run setup:" >&2
  echo "" >&2
  echo "  npm install -g @earendil-works/pi-coding-agent" >&2
  echo "  bash setup.sh" >&2
  echo "" >&2
  exit 1
fi
PI_VERSION="$(install_state_pi_version)"
if [[ -n "$PI_VERSION" ]]; then
  if ! install_state_check_pi_version; then
    echo "" >&2
    echo "ERROR: Pi v$(install_state_min_pi_version)+ required, found v${PI_VERSION}. Upgrade:" >&2
    echo "  npm install -g @earendil-works/pi-coding-agent@latest" >&2
    echo "  Then re-run: bash setup.sh" >&2
    echo "" >&2
    exit 1
  fi
  echo "pi ${PI_VERSION}: ok (≥v$(install_state_min_pi_version))"
else
  echo "pi (version not detected — continuing): ok"
fi

# uv
if ! install_state_check_uv; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: uv missing; would install uv with https://astral.sh/uv/install.sh"
  else
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi
if install_state_check_uv; then
  echo "uv $(uv --version): ok"
fi

# Brain DB path
export BRAIN_DB_PATH="$(install_state_brain_db_path)"
echo "BRAIN_DB_PATH: $BRAIN_DB_PATH"

# Install brain CLI and init DB
BRAIN_GIT_URL="$(install_state_knowledge_brain_source)"
echo ""
echo "Installing brain CLI..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: uv tool install --from \"$BRAIN_GIT_URL\" knowledge-brain --reinstall"
else
  uv tool install --from "$BRAIN_GIT_URL" knowledge-brain --reinstall
fi
# uv tool installs to ~/.local/bin — warn if not on PATH so brain is immediately usable
if [[ "$DRY_RUN" -eq 0 ]] && ! install_state_check_brain_cli; then
  export PATH="$HOME/.local/bin:$PATH"
  if ! install_state_check_brain_cli; then
    echo ""
    echo "WARNING: 'brain' not found on PATH after install." >&2
    echo "  Add to your shell profile and re-run: export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
    echo "  Then re-run: bash setup.sh" >&2
    exit 1
  fi
  echo "NOTE: Added ~/.local/bin to PATH for this session. Add to your shell profile to persist."
fi
if [[ -f "$BRAIN_DB_PATH" ]]; then
  echo "Brain DB already exists at $BRAIN_DB_PATH; skipping init."
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: brain --db-path \"$BRAIN_DB_PATH\" init"
  else
    brain --db-path "$BRAIN_DB_PATH" init
  fi
fi


# Install Agent OS Pi extension
AGENT_OS_EXTENSION="$(install_state_agent_os_source)"
echo ""
echo "Installing Agent OS Pi extension..."
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: pi install \"$AGENT_OS_EXTENSION\""
  echo "DRY RUN: verify Agent OS version matches $(install_state_agent_os_expected_version) where Pi exposes it"
else
  pi install "$AGENT_OS_EXTENSION"
  ACTUAL_AGENT_VERSION="$(install_state_agent_os_actual_version)"
  if [[ "$ACTUAL_AGENT_VERSION" != "unknown" && "$ACTUAL_AGENT_VERSION" != "$(install_state_agent_os_expected_version)" ]]; then
    echo "WARNING: Agent OS version does not match expected $(install_state_agent_os_expected_version): $ACTUAL_AGENT_VERSION" >&2
    echo "  Repair: bash update.sh --dry-run, then bash update.sh" >&2
  fi
  echo "Agent OS extension installed: ok"
fi

# Write install manifest (used by doctor and upgrade)
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: write .agent-os/install-manifest.json"
else
  BRAIN_VERSION="$(install_state_brain_version || true)"
  EXPECTED_BRAIN_VERSION="$(install_state_knowledge_brain_expected_version)"
  if [[ "$EXPECTED_BRAIN_VERSION" != "unknown" && "$BRAIN_VERSION" != *"$EXPECTED_BRAIN_VERSION"* ]]; then
    echo "WARNING: brain version does not match expected $EXPECTED_BRAIN_VERSION: ${BRAIN_VERSION:-unknown}" >&2
    echo "  Repair: uv tool install --from \"$BRAIN_GIT_URL\" knowledge-brain --reinstall" >&2
  fi
  MANIFEST_PATH="$(install_state_write_manifest "${BRAIN_VERSION:-unknown}" "$AGENT_OS_EXTENSION" "user-global" "$BRAIN_GIT_URL")"
  echo "Install manifest: $MANIFEST_PATH"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Configure your model provider: run \`pi\`, then \`/login\`, then choose your provider."
echo "  2. Open Pi in this directory: pi"
echo "  3. Run /init"
echo "  4. Run /doctor"
echo "  5. Start a task: /flow \"<your goal>\""
