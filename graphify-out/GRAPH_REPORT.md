# Graph Report - .  (2026-05-16)

## Corpus Check
- Corpus is ~4,549 words - fits in a single context window. You may not need a graph.

## Summary
- 99 nodes · 125 edges · 19 communities (14 shown, 5 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.78)
- Token cost: 24,734 input · 4,000 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Project Overview & Commands|Project Overview & Commands]]
- [[_COMMUNITY_Install State - Tooling Checks|Install State - Tooling Checks]]
- [[_COMMUNITY_Install State - Versions & Manifest|Install State - Versions & Manifest]]
- [[_COMMUNITY_Manifest Validation|Manifest Validation]]
- [[_COMMUNITY_Approval & Flow Commands|Approval & Flow Commands]]
- [[_COMMUNITY_Install State - Brain DB & Repo|Install State - Brain DB & Repo]]
- [[_COMMUNITY_Graphify Integration Rules|Graphify Integration Rules]]
- [[_COMMUNITY_Runtime Sessions Commands|Runtime Sessions Commands]]
- [[_COMMUNITY_Settings Hooks Config|Settings Hooks Config]]
- [[_COMMUNITY_Local Permissions Config|Local Permissions Config]]
- [[_COMMUNITY_Pi Version Checks|Pi Version Checks]]
- [[_COMMUNITY_Setup Script|Setup Script]]
- [[_COMMUNITY_Smoke Install Docs|Smoke Install Docs]]
- [[_COMMUNITY_Status Command Docs|Status Command Docs]]

## God Nodes (most connected - your core abstractions)
1. `install_state_write_manifest()` - 15 edges
2. `/flow primary workflow` - 8 edges
3. `install_state_manifest_path()` - 7 edges
4. `agent-os-starter project` - 7 edges
5. `install_state_repo_root()` - 5 edges
6. `install_state_brain_db_path()` - 5 edges
7. `install_state_manifest_field()` - 5 edges
8. `install_state_agent_os_resolved_path()` - 5 edges
9. `graphify knowledge graph project rules` - 5 edges
10. `Agent OS Pi extension` - 4 edges

## Surprising Connections (you probably didn't know these)
- `graphify knowledge graph project rules` --conceptually_related_to--> `agent-os-starter project`  [INFERRED]
  CLAUDE.md → README.md

## Hyperedges (group relationships)
- **Flow lifecycle phases** — readme_grill_command, readme_plan_command, readme_run_command, readme_verify_command, readme_review_command, readme_evaluate_command [EXTRACTED 1.00]
- **Install lifecycle scripts** — readme_setup_sh, readme_doctor_sh, readme_update_sh, readme_uninstall_sh [EXTRACTED 1.00]
- **Memory persistence flow** — readme_remember_command, readme_knowledge_db, readme_knowledge_jsonl, readme_memory_command [EXTRACTED 1.00]

## Communities (19 total, 5 thin omitted)

### Community 0 - "Project Overview & Commands"
Cohesion: 0.13
Nodes (18): Agent OS Pi extension, agent-os-starter project, brain CLI, brain_playground examples repo, /doctor command, doctor.sh health check, /init command, agent-os-install.env config (+10 more)

### Community 1 - "Install State - Tooling Checks"
Cohesion: 0.23
Nodes (5): install_state_agent_os_actual_version(), install_state_agent_os_resolved_path(), install_state_agent_os_source(), install_state_check_agent_os_extension_registered(), install_state_pi_list()

### Community 2 - "Install State - Versions & Manifest"
Cohesion: 0.25
Nodes (9): install_state_agent_os_channel(), install_state_agent_os_expected_version(), install_state_agent_os_version_from_source(), install_state_brain_path(), install_state_knowledge_brain_expected_version(), install_state_knowledge_brain_source(), install_state_node_version(), install_state_pi_agent_dir() (+1 more)

### Community 3 - "Manifest Validation"
Cohesion: 0.25
Nodes (8): install_state_agent_os_actual_source(), install_state_check_manifest_exists(), install_state_check_manifest_fields(), install_state_check_manifest_json(), install_state_check_manifest_schema(), install_state_manifest_field(), install_state_manifest_path(), install_state_manifest_schema_version()

### Community 4 - "Approval & Flow Commands"
Cohesion: 0.25
Nodes (8): Approval gates lifecycle, /continue resume command, /evaluate phase, /flow primary workflow, /grill phase, /plan phase, /review phase, /verify phase

### Community 6 - "Install State - Brain DB & Repo"
Cohesion: 0.33
Nodes (6): install_state_brain_db_path(), install_state_check_agent_os_dir(), install_state_check_brain_db(), install_state_check_brain_list(), install_state_repo_root(), install_state_starter_commit()

### Community 7 - "Graphify Integration Rules"
Cohesion: 0.5
Nodes (5): GRAPH_REPORT.md primary map, graphify knowledge graph project rules, graphify query/path/explain commands, graphify update command, graphify-out wiki index

### Community 9 - "Runtime Sessions Commands"
Cohesion: 0.5
Nodes (4): /diagnose command, /flight session timeline, /quick-task command, .agent-os runtime sessions

### Community 12 - "Pi Version Checks"
Cohesion: 0.67
Nodes (3): install_state_check_pi_version(), install_state_min_pi_version(), install_state_pi_version()

## Knowledge Gaps
- **24 isolated node(s):** `BRAIN_DB_PATH`, `PreToolUse`, `allow`, `graphify query/path/explain commands`, `graphify update command` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `agent-os-starter project` connect `Project Overview & Commands` to `Graphify Integration Rules`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **Why does `/flow primary workflow` connect `Approval & Flow Commands` to `Project Overview & Commands`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **What connects `BRAIN_DB_PATH`, `PreToolUse`, `allow` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Overview & Commands` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._