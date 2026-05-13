#!/usr/bin/env bash

install_state_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
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
  pi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

install_state_check_pi_version() {
  local pi_version
  pi_version="$(install_state_pi_version)"
  [[ -z "$pi_version" ]] && return 0
  node -e "const v='${pi_version}'.split('.').map(Number);process.exit((v[0]>0||(v[0]===0&&v[1]>=74))?0:1)" 2>/dev/null
}

install_state_check_uv() {
  command -v uv &>/dev/null
}

install_state_check_brain_cli() {
  command -v brain &>/dev/null
}

install_state_check_api_key() {
  [[ -n "${ANTHROPIC_API_KEY:-}" ]]
}

install_state_manifest_path() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  printf '%s\n' "$repo_root/.agent-os/install-manifest.json"
}

install_state_check_agent_os_dir() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  [[ -d "$repo_root/.agent-os" ]]
}

install_state_check_contract_index() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  [[ -f "$repo_root/.agent-os/contracts/index.json" ]]
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
    node -e "const m=JSON.parse(require('fs').readFileSync(process.argv[1],'utf-8')); ['installed_at','knowledge_brain_version','agent_os_extension','brain_db_path'].forEach(k=>{if(!m[k])throw new Error(k)})" "$manifest" 2>/dev/null
    return $?
  fi
  python3 -c "import json,sys; m=json.load(open(sys.argv[1])); [m[k] for k in ['installed_at','knowledge_brain_version','agent_os_extension','brain_db_path']]" "$manifest" 2>/dev/null
}

install_state_check_data_store_dir() {
  local repo_root
  repo_root="$(install_state_repo_root)"
  [[ -d "$repo_root/data_store" ]]
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
  pi ext list 2>/dev/null | grep -q agent-os || pi extensions list 2>/dev/null | grep -q agent-os
}

install_state_write_manifest() {
  local knowledge_brain_version="$1"
  local agent_os_extension="$2"
  local manifest_path
  local pi_version
  manifest_path="$(install_state_manifest_path)"
  pi_version="$(install_state_pi_version)"
  mkdir -p "$(dirname "$manifest_path")"
  cat > "$manifest_path" <<EOF
{
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "knowledge_brain_version": "$knowledge_brain_version",
  "agent_os_extension": "$agent_os_extension",
  "brain_db_path": "$(install_state_brain_db_path)",
  "node_version": "$(install_state_node_version)",
  "uv_version": "$(uv --version 2>&1 | head -1)",
  "pi_version": "${pi_version:-unknown}"
}
EOF
  printf '%s\n' "$manifest_path"
}
