#!/usr/bin/env bash
# Smoke test — verifies setup is complete without mutating any state.
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
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
check "node 20+" "node -e \"process.exit(parseInt(process.versions.node) < 20 ? 1 : 0)\""
check "pi CLI available" "command -v pi"
check "brain CLI available" "command -v brain"
check "uv available" "command -v uv"

# Project structure
check ".agent-os/ exists" "test -d .agent-os"
check ".agent-os/contracts/index.json exists" "test -f .agent-os/contracts/index.json"
check ".agent-os/install-manifest.json exists" "test -f .agent-os/install-manifest.json"
check "install-manifest.json is valid JSON" "node -e \"JSON.parse(require('fs').readFileSync('.agent-os/install-manifest.json','utf-8'))\" 2>/dev/null || python3 -c \"import json,sys; json.load(open('.agent-os/install-manifest.json'))\""
check "install-manifest.json has required fields" "node -e \"const m=JSON.parse(require('fs').readFileSync('.agent-os/install-manifest.json','utf-8')); ['installed_at','knowledge_brain_version','agent_os_extension','brain_db_path'].forEach(k=>{if(!m[k])throw new Error(k)})\" 2>/dev/null"
check "data_store/ exists" "test -d data_store"

# Brain DB
BRAIN_DB="${BRAIN_DB_PATH:-$(pwd)/data_store/knowledge.db}"
check "brain DB exists at $BRAIN_DB" "test -f \"$BRAIN_DB\""
check "brain CLI can list (DB readable)" "brain --db-path \"$BRAIN_DB\" list --limit 1"

# Pi extension (best-effort — pi ext list may not exist in all versions)
if command -v pi &>/dev/null; then
  check "Agent OS extension registered" "pi ext list 2>/dev/null | grep -q agent-os || pi extensions list 2>/dev/null | grep -q agent-os"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo "Run 'bash setup.sh' to fix failures."
  exit 1
fi
echo "All checks passed. Run 'pi', then '/init', '/doctor', and '/flow \"<goal>\"' to start."
