#!/usr/bin/env bash
set -euo pipefail

echo "=== agent-os-starter setup ==="
echo ""

# Node 20+
if ! node -e "process.exit(parseInt(process.versions.node) < 20 ? 1 : 0)" 2>/dev/null; then
  echo "ERROR: Node 20+ required. Install from https://nodejs.org" >&2
  exit 1
fi
echo "Node $(node -e 'process.stdout.write(process.versions.node)'): ok"

# uv
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
echo "uv $(uv --version): ok"

# API key
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo ""
  echo "ERROR: ANTHROPIC_API_KEY is not set." >&2
  echo "  export ANTHROPIC_API_KEY=sk-ant-..." >&2
  echo "  Then re-run: bash setup.sh" >&2
  exit 1
fi
echo "ANTHROPIC_API_KEY: set"

# Brain DB path
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BRAIN_DB_PATH="${BRAIN_DB_PATH:-$REPO_ROOT/data_store/knowledge.db}"
echo "BRAIN_DB_PATH: $BRAIN_DB_PATH"

# Install brain CLI and init DB
BRAIN_GIT_URL="git+https://github.com/agnivadc/knowledge-brain.git@v1.0.0"
echo ""
echo "Installing brain CLI..."
uv tool install --from "$BRAIN_GIT_URL" knowledge-brain --reinstall
if [[ -f "$BRAIN_DB_PATH" ]]; then
  echo "Brain DB already exists at $BRAIN_DB_PATH; skipping init."
else
  brain --db-path "$BRAIN_DB_PATH" init
fi


# Install Agent OS Pi extension
AGENT_OS_EXTENSION="git:github.com/algoSiliguri/Agent_OS@v1.4.0"
echo ""
echo "Installing Agent OS Pi extension..."
if command -v pi &>/dev/null; then
  pi install "$AGENT_OS_EXTENSION"
  echo "Agent OS extension installed: ok"
else
  echo "WARNING: 'pi' not found. Install it first:"
  echo "  npm install -g @earendil-works/pi-coding-agent"
  echo "Then run: pi install $AGENT_OS_EXTENSION"
fi

# Write install manifest (used by doctor and upgrade)
MANIFEST_PATH="$REPO_ROOT/.agent-os/install-manifest.json"
mkdir -p "$(dirname "$MANIFEST_PATH")"
cat > "$MANIFEST_PATH" <<EOF
{
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "knowledge_brain_version": "v1.0.0",
  "agent_os_extension": "$AGENT_OS_EXTENSION",
  "brain_db_path": "$BRAIN_DB_PATH",
  "node_version": "$(node -e 'process.stdout.write(process.versions.node)')",
  "uv_version": "$(uv --version 2>&1 | head -1)"
}
EOF
echo "Install manifest: $MANIFEST_PATH"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Open Pi in this directory: pi"
echo "  2. Run /init"
echo "  3. Run /doctor"
