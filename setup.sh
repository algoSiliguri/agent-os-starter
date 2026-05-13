#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

echo "=== agent-os-starter setup ==="
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
    echo "ERROR: Pi v0.74.0+ required, found v${PI_VERSION}. Upgrade:" >&2
    echo "  npm install -g @earendil-works/pi-coding-agent@latest" >&2
    echo "  Then re-run: bash setup.sh" >&2
    echo "" >&2
    exit 1
  fi
  echo "pi ${PI_VERSION}: ok (≥v0.74.0)"
else
  echo "pi (version not detected — continuing): ok"
fi

# uv
if ! install_state_check_uv; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
echo "uv $(uv --version): ok"

# API key
if ! install_state_check_api_key; then
  echo ""
  echo "ERROR: ANTHROPIC_API_KEY is not set." >&2
  echo "  export ANTHROPIC_API_KEY=sk-ant-..." >&2
  echo "  Then re-run: bash setup.sh" >&2
  exit 1
fi
echo "ANTHROPIC_API_KEY: set"

# Brain DB path
export BRAIN_DB_PATH="$(install_state_brain_db_path)"
echo "BRAIN_DB_PATH: $BRAIN_DB_PATH"

# Install brain CLI and init DB
BRAIN_GIT_URL="git+https://github.com/agnivadc/knowledge-brain.git@v1.0.0"
echo ""
echo "Installing brain CLI..."
uv tool install --from "$BRAIN_GIT_URL" knowledge-brain --reinstall
# uv tool installs to ~/.local/bin — warn if not on PATH so brain is immediately usable
if ! install_state_check_brain_cli; then
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
  brain --db-path "$BRAIN_DB_PATH" init
fi


# Install Agent OS Pi extension
AGENT_OS_EXTENSION="git:github.com/algoSiliguri/Agent_OS@v1.4.0"
echo ""
echo "Installing Agent OS Pi extension..."
pi install "$AGENT_OS_EXTENSION"
echo "Agent OS extension installed: ok"

# Write install manifest (used by doctor and upgrade)
MANIFEST_PATH="$(install_state_write_manifest "v1.0.0" "$AGENT_OS_EXTENSION")"
echo "Install manifest: $MANIFEST_PATH"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Open Pi in this directory: pi"
echo "  2. Run /init"
echo "  3. Run /doctor"
echo "  4. Start a task: /flow \"<your goal>\""
