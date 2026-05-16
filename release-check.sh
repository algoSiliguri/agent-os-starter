#!/usr/bin/env bash
# Non-mutating release readiness check for lifecycle install targets.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/install-state.sh
source "$REPO_ROOT/lib/install-state.sh"

PASS=0
FAIL=0
WARN=0

pass() { echo "  [ok] $1"; PASS=$((PASS + 1)); }
warn() { echo "  [!] $1"; WARN=$((WARN + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

json_version() {
  node -e "const p=require(process.argv[1]); process.stdout.write(String(p.version || 'unknown'))" "$1" 2>/dev/null || printf '%s\n' "unknown"
}

toml_project_version() {
  sed -n 's/^version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

remote_tag_exists() {
  local repo="$1"
  local tag="$2"
  git -C "$repo" ls-remote --tags origin "$tag" 2>/dev/null | grep -q "refs/tags/$tag$"
}

contains_stale_ref() {
  local stale_pattern="Agent_OS@v1\\."4"\\.0"
  grep -R "$stale_pattern" "$REPO_ROOT/setup.sh" "$REPO_ROOT/update.sh" "$REPO_ROOT/uninstall.sh" "$REPO_ROOT/doctor.sh" "$REPO_ROOT/smoke-user-install.sh" "$REPO_ROOT/lib/install-state.sh" >/dev/null 2>&1
}

echo "=== agent-os-starter release check ==="
echo ""
echo "Lifecycle config: $(install_state_config_path)"
echo "Agent OS target: $(install_state_agent_os_source)"
echo "Agent OS expected version: $(install_state_agent_os_expected_version)"
echo "Agent OS install channel: $(install_state_agent_os_channel)"
echo "knowledge-brain target: $(install_state_knowledge_brain_source)"
echo "knowledge-brain expected version: $(install_state_knowledge_brain_expected_version)"
echo "Manifest schema: $(install_state_manifest_schema_version)"
echo ""

if [[ -f "$(install_state_config_path)" ]]; then
  pass "shared lifecycle config exists"
else
  fail "shared lifecycle config missing"
fi

AGENT_OS_ADJACENT="$(cd "$REPO_ROOT/.." && pwd)/Agent_OS"
KB_ADJACENT="$(cd "$REPO_ROOT/.." && pwd)/knowledge-brain"

if [[ -f "$AGENT_OS_ADJACENT/package.json" ]]; then
  LOCAL_AGENT_VERSION="$(json_version "$AGENT_OS_ADJACENT/package.json")"
  echo "Adjacent Agent_OS package version: $LOCAL_AGENT_VERSION"
  if [[ "$LOCAL_AGENT_VERSION" == "$(install_state_agent_os_expected_version)" ]]; then
    pass "Agent_OS expected version matches adjacent package.json"
  else
    fail "Agent_OS expected version does not match adjacent package.json"
    echo "       Expected config: $(install_state_agent_os_expected_version)"
    echo "       package.json:     $LOCAL_AGENT_VERSION"
  fi
  if git -C "$AGENT_OS_ADJACENT" tag --list "v$(install_state_agent_os_expected_version)" | grep -q .; then
    AGENT_TAG_EXISTS=1
    pass "local Agent_OS tag v$(install_state_agent_os_expected_version) exists"
  else
    AGENT_TAG_EXISTS=0
    warn "local Agent_OS tag v$(install_state_agent_os_expected_version) is missing"
  fi
  if remote_tag_exists "$AGENT_OS_ADJACENT" "v$(install_state_agent_os_expected_version)"; then
    pass "remote Agent_OS tag v$(install_state_agent_os_expected_version) exists"
  else
    fail "remote Agent_OS tag v$(install_state_agent_os_expected_version) is missing"
    echo "       Release action: git -C \"$AGENT_OS_ADJACENT\" push origin v$(install_state_agent_os_expected_version)"
  fi
else
  AGENT_TAG_EXISTS=unknown
  warn "adjacent Agent_OS repo not found; skipped local version check"
fi

if [[ -f "$KB_ADJACENT/pyproject.toml" ]]; then
  LOCAL_KB_VERSION="$(toml_project_version "$KB_ADJACENT/pyproject.toml")"
  echo "Adjacent knowledge-brain package version: $LOCAL_KB_VERSION"
  if [[ "$LOCAL_KB_VERSION" == "$(install_state_knowledge_brain_expected_version)" ]]; then
    pass "knowledge-brain expected version matches adjacent pyproject.toml"
  else
    fail "knowledge-brain expected version does not match adjacent pyproject.toml"
  fi
  if git -C "$KB_ADJACENT" tag --list "v$(install_state_knowledge_brain_expected_version)" | grep -q .; then
    pass "local knowledge-brain tag v$(install_state_knowledge_brain_expected_version) exists"
  else
    fail "local knowledge-brain tag v$(install_state_knowledge_brain_expected_version) is missing"
  fi
  if remote_tag_exists "$KB_ADJACENT" "v$(install_state_knowledge_brain_expected_version)"; then
    pass "remote knowledge-brain tag v$(install_state_knowledge_brain_expected_version) exists"
  else
    fail "remote knowledge-brain tag v$(install_state_knowledge_brain_expected_version) is missing"
    echo "       Release action: git -C \"$KB_ADJACENT\" push origin v$(install_state_knowledge_brain_expected_version)"
  fi
else
  warn "adjacent knowledge-brain repo not found; skipped local version check"
fi

AGENT_REF="$(install_state_agent_os_source)"
AGENT_EXPECTED="$(install_state_agent_os_expected_version)"
if [[ "$AGENT_REF" == *"@v$AGENT_EXPECTED" && "${AGENT_TAG_EXISTS:-unknown}" != "0" ]]; then
  pass "Agent_OS install ref is aligned to expected version tag"
elif [[ "$AGENT_REF" == *"@main" && "$(install_state_agent_os_channel)" == pre-release* ]]; then
  fail "Agent_OS release source is not cut yet"
  echo "       Current config: $AGENT_REF ($(install_state_agent_os_channel))"
  echo "       Expected release ref: git:github.com/algoSiliguri/Agent_OS@v$AGENT_EXPECTED"
  echo "       Local tag v$AGENT_EXPECTED exists: ${AGENT_TAG_EXISTS:-unknown}"
  echo "       Release action: create and push tag v$AGENT_EXPECTED, then set AGENT_OS_INSTALL_REF=\"git:github.com/algoSiliguri/Agent_OS@v$AGENT_EXPECTED\" and AGENT_OS_INSTALL_CHANNEL=\"released\"."
elif [[ "$AGENT_REF" == *"@v$AGENT_EXPECTED" && "${AGENT_TAG_EXISTS:-unknown}" == "0" ]]; then
  fail "Agent_OS install ref targets v$AGENT_EXPECTED but the local tag is missing"
  echo "       Release action: create tag v$AGENT_EXPECTED before publishing this config."
else
  fail "Agent_OS install ref is not aligned with expected version"
  echo "       Ref:      $AGENT_REF"
  echo "       Expected: v$AGENT_EXPECTED"
fi

KB_REF="$(install_state_knowledge_brain_source)"
KB_EXPECTED="$(install_state_knowledge_brain_expected_version)"
if [[ "$KB_REF" == *"@v$KB_EXPECTED" ]]; then
  pass "knowledge-brain install ref is aligned to expected version tag"
else
  fail "knowledge-brain install ref is not aligned with expected version"
  echo "       Ref:      $KB_REF"
  echo "       Expected: v$KB_EXPECTED"
fi

if contains_stale_ref; then
  fail "lifecycle scripts still contain stale Agent_OS v1.4.0 refs"
else
  pass "no stale Agent_OS v1.4.0 refs in lifecycle scripts"
fi

if grep -n "ANTHROPIC_API_KEY" \
    "$REPO_ROOT/setup.sh" \
    "$REPO_ROOT/doctor.sh" \
    "$REPO_ROOT/update.sh" \
    "$REPO_ROOT/uninstall.sh" \
    "$REPO_ROOT/smoke-user-install.sh" \
    2>/dev/null; then
  fail "active lifecycle scripts must not reference ANTHROPIC_API_KEY; use Pi /login provider-neutral flow"
else
  pass "no ANTHROPIC_API_KEY references in active lifecycle scripts"
fi

if grep -i "required" "$REPO_ROOT/.env.example" 2>/dev/null | grep -i "ANTHROPIC_API_KEY"; then
  fail ".env.example must not mark ANTHROPIC_API_KEY as required"
else
  pass ".env.example does not mark ANTHROPIC_API_KEY as required"
fi

if grep -q "source \"\$REPO_ROOT/lib/install-state.sh\"" "$REPO_ROOT/setup.sh" "$REPO_ROOT/update.sh" "$REPO_ROOT/uninstall.sh" "$REPO_ROOT/doctor.sh" >/dev/null 2>&1 && grep -q "agent-os-install.env" "$REPO_ROOT/lib/install-state.sh"; then
  pass "lifecycle scripts load install-state, which sources shared config"
else
  fail "one or more lifecycle scripts do not load shared lifecycle config"
fi

if [[ "$(install_state_manifest_schema_version)" =~ ^[0-9]+$ ]]; then
  pass "manifest schema version is numeric"
else
  fail "manifest schema version is invalid: $(install_state_manifest_schema_version)"
fi

echo ""
echo "Dry-run probes:"
if bash "$REPO_ROOT/setup.sh" --dry-run >/tmp/agent-os-starter-release-setup.out 2>/tmp/agent-os-starter-release-setup.err; then
  pass "setup.sh --dry-run works"
else
  fail "setup.sh --dry-run failed"
  sed 's/^/       /' /tmp/agent-os-starter-release-setup.err
fi
if bash "$REPO_ROOT/update.sh" --dry-run >/tmp/agent-os-starter-release-update.out 2>/tmp/agent-os-starter-release-update.err; then
  pass "update.sh --dry-run works"
else
  fail "update.sh --dry-run failed"
  sed 's/^/       /' /tmp/agent-os-starter-release-update.err
fi
if bash "$REPO_ROOT/uninstall.sh" --dry-run >/tmp/agent-os-starter-release-uninstall.out 2>/tmp/agent-os-starter-release-uninstall.err; then
  pass "uninstall.sh --dry-run works"
else
  fail "uninstall.sh --dry-run failed"
  sed 's/^/       /' /tmp/agent-os-starter-release-uninstall.err
fi

echo ""
echo "Results: $PASS passed, $WARN warnings, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
