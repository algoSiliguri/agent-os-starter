#!/usr/bin/env bash

INSTALL_STATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_STATE_REPO_ROOT="$(cd "$INSTALL_STATE_LIB_DIR/.." && pwd)"
INSTALL_STATE_CONFIG_PATH="$INSTALL_STATE_REPO_ROOT/agent-os-install.env"

if [[ -f "$INSTALL_STATE_CONFIG_PATH" ]]; then
  # shellcheck source=../agent-os-install.env
  source "$INSTALL_STATE_CONFIG_PATH"
fi

install_state_repo_root() {
  printf '%s\n' "$INSTALL_STATE_REPO_ROOT"
}

install_state_config_path() {
  printf '%s\n' "$INSTALL_STATE_CONFIG_PATH"
}

install_state_agent_os_source() {
  printf '%s\n' "${AGENT_OS_EXTENSION:-${AGENT_OS_INSTALL_REF:-git:github.com/algoSiliguri/Agent_OS@v1.6.1}}"
}

install_state_agent_os_expected_version() {
  printf '%s\n' "${AGENT_OS_EXPECTED_VERSION:-unknown}"
}

install_state_agent_os_channel() {
  printf '%s\n' "${AGENT_OS_INSTALL_CHANNEL:-unknown}"
}

install_state_knowledge_brain_source() {
  printf '%s\n' "${KNOWLEDGE_BRAIN_SOURCE:-${KNOWLEDGE_BRAIN_INSTALL_REF:-git+https://github.com/agnivadc/knowledge-brain.git@v1.0.1}}"
}

install_state_knowledge_brain_expected_version() {
  printf '%s\n' "${KNOWLEDGE_BRAIN_EXPECTED_VERSION:-unknown}"
}

install_state_min_pi_version() {
  printf '%s\n' "${MIN_PI_VERSION:-0.74.0}"
}

install_state_manifest_schema_version() {
  printf '%s\n' "${INSTALL_MANIFEST_SCHEMA_VERSION:-1}"
}

install_state_pi_agent_dir() {
  printf '%s\n' "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
}

install_state_brain_db_path() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  printf '%s\n' "${BRAIN_DB_PATH:-$repo_root/data_store/knowledge.db}"
}

install_state_node_version() {
  node -e 'process.stdout.write(process.versions.node)' 2>/dev/null
}

install_state_check_node() {
  node -e "process.exit(parseInt(process.versions.node) < 20 ? 1 : 0)" 2>/dev/null
}

install_state_check_pi_cli() {
  command -v pi &>/dev/null
}

install_state_pi_version() {
  pi --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true
}

install_state_check_pi_version() {
  local pi_version
  local min_version
  pi_version="$(install_state_pi_version)"
  min_version="$(install_state_min_pi_version)"
  [[ -z "$pi_version" ]] && return 0
  node -e "const a='${pi_version}'.split('.').map(Number),b='${min_version}'.split('.').map(Number); for (let i=0;i<3;i++){if((a[i]||0)>(b[i]||0))process.exit(0); if((a[i]||0)<(b[i]||0))process.exit(1)} process.exit(0)" 2>/dev/null
}

install_state_check_uv() {
  command -v uv &>/dev/null
}

install_state_check_brain_cli() {
  command -v brain &>/dev/null
}

install_state_brain_path() {
  command -v brain 2>/dev/null || true
}

install_state_brain_version() {
  brain --version 2>&1 | head -1
}

install_state_agent_os_version_from_source() {
  local source="$1"
  local expected
  expected="$(install_state_agent_os_expected_version)"
  if [[ "$expected" != "unknown" ]]; then
    printf '%s\n' "$expected"
    return
  fi
  case "$source" in
    *@v*) printf '%s\n' "${source##*@}" ;;
    *@*) printf '%s\n' "${source##*@}" ;;
    *) printf '%s\n' "unknown" ;;
  esac
}

install_state_starter_commit() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf '%s\n' "unknown"
}

install_state_manifest_path() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  printf '%s\n' "$repo_root/.agent-os/install-manifest.json"
}

install_state_manifest_field() {
  local field="$1"
  local manifest
  manifest="$(install_state_manifest_path)"
  [[ -f "$manifest" ]] || return 1
  node -e "const m=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); const v=m[process.argv[2]]; if (v === undefined || v === null || v === '') process.exit(1); process.stdout.write(String(v));" "$manifest" "$field" 2>/dev/null
}

install_state_check_agent_os_dir() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  [[ -d "$repo_root/.agent-os" ]]
}

install_state_check_manifest_exists() {
  [[ -f "$(install_state_manifest_path)" ]]
}

install_state_check_manifest_json() {
  local manifest
  manifest="$(install_state_manifest_path)"
  if command -v node &>/dev/null; then
    node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf-8'))" "$manifest" 2>/dev/null
    return $?
  fi
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$manifest" 2>/dev/null
}

install_state_check_manifest_fields() {
  local manifest
  manifest="$(install_state_manifest_path)"
  if command -v node &>/dev/null; then
    node -e "const m=JSON.parse(require('fs').readFileSync(process.argv[1],'utf-8')); ['schema_version','installed_at','installer_version','agent_os_package','agent_os_version','agent_os_source','knowledge_brain_version','knowledge_brain_source','brain_db_path','pi_agent_dir','install_mode'].forEach(k=>{if(!m[k])throw new Error(k)})" "$manifest" 2>/dev/null
    return $?
  fi
  python3 -c "import json,sys; m=json.load(open(sys.argv[1])); [m[k] for k in ['schema_version','installed_at','installer_version','agent_os_package','agent_os_version','agent_os_source','knowledge_brain_version','knowledge_brain_source','brain_db_path','pi_agent_dir','install_mode']]" "$manifest" 2>/dev/null
}

install_state_check_manifest_schema() {
  local actual
  actual="$(install_state_manifest_field schema_version 2>/dev/null || true)"
  [[ "$actual" == "$(install_state_manifest_schema_version)" ]]
}

install_state_check_brain_db() {
  [[ -f "$(install_state_brain_db_path)" ]]
}

install_state_check_brain_list() {
  local brain_db
  brain_db="$(install_state_brain_db_path)"
  brain --db-path "$brain_db" list --limit 1 &>/dev/null
}

install_state_check_agent_os_extension_registered() {
  pi list 2>/dev/null | grep -Fq "$(install_state_agent_os_source)"
}

install_state_pi_list() {
  pi list 2>/dev/null || true
}

install_state_agent_os_resolved_path() {
  local source
  source="$(install_state_agent_os_source)"
  install_state_pi_list | awk -v source="$source" '
    index($0, source) { found=1; next }
    found && /^[[:space:]]+\// { gsub(/^[[:space:]]+/, "", $0); print; exit }
  '
}

install_state_agent_os_actual_version() {
  local manifest_version
  local resolved_path
  manifest_version="$(install_state_manifest_field agent_os_version 2>/dev/null || true)"
  if [[ -n "$manifest_version" ]]; then
    printf '%s\n' "$manifest_version"
    return
  fi
  resolved_path="$(install_state_agent_os_resolved_path)"
  if [[ -n "$resolved_path" && -f "$resolved_path/package.json" ]]; then
    node -e "const p=require(process.argv[1]); process.stdout.write(String(p.version || 'unknown'))" "$resolved_path/package.json" 2>/dev/null && return
  fi
  printf '%s\n' "unknown"
}

install_state_agent_os_actual_source() {
  install_state_manifest_field agent_os_source 2>/dev/null || printf '%s\n' "unknown"
}

install_state_write_manifest() {
  local knowledge_brain_version="$1"
  local agent_os_source="$2"
  local install_mode="${3:-user-global}"
  local knowledge_brain_source="${4:-$(install_state_knowledge_brain_source)}"
  local manifest_path
  local pi_version
  local resolved_path
  local agent_os_version
  manifest_path="$(install_state_manifest_path)"
  pi_version="$(install_state_pi_version)"
  resolved_path="$(install_state_agent_os_resolved_path)"
  agent_os_version="$(install_state_agent_os_version_from_source "$agent_os_source")"
  mkdir -p "$(dirname "$manifest_path")"
  cat > "$manifest_path" <<EOF
{
  "schema_version": $(install_state_manifest_schema_version),
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "installer_version": "$(install_state_starter_commit)",
  "agent_os_package": "@agnivadc/agent-os",
  "agent_os_version": "$agent_os_version",
  "agent_os_source": "$agent_os_source",
  "agent_os_expected_version": "$(install_state_agent_os_expected_version)",
  "agent_os_install_channel": "$(install_state_agent_os_channel)",
  "agent_os_resolved_path": "${resolved_path:-unknown}",
  "agent_os_extension": "$agent_os_source",
  "knowledge_brain_version": "$knowledge_brain_version",
  "knowledge_brain_expected_version": "$(install_state_knowledge_brain_expected_version)",
  "knowledge_brain_source": "$knowledge_brain_source",
  "knowledge_brain_path": "$(install_state_brain_path)",
  "brain_db_path": "$(install_state_brain_db_path)",
  "pi_agent_dir": "$(install_state_pi_agent_dir)",
  "install_mode": "$install_mode",
  "node_version": "$(install_state_node_version)",
  "uv_version": "$(uv --version 2>&1 | head -1)",
  "pi_version": "${pi_version:-unknown}"
}
EOF
  printf '%s\n' "$manifest_path"
}
