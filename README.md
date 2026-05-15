# agent-os-starter

Local governed AI agent for your project. Runs in [Pi](https://pi.ai) via the Agent OS extension.

**What it installs:** Pi extension + local knowledge DB (SQLite, project-local)
**What it writes:** `.agent-os/` (runtime, gitignored) · `data_store/knowledge.db` (gitignored) · `data_store/knowledge.jsonl` (committed)
**What it does not do:** network calls during normal use · write outside your project directory · auto-approve dangerous commands

---

## Prerequisites

- Node.js 20+
- Pi coding agent v0.74.0+: `npm install -g @earendil-works/pi-coding-agent`
- `ANTHROPIC_API_KEY` set in your shell (or any other model API key — see Pi docs)

---

## Start

```bash
# 0. Install Pi (once per machine)
npm install -g @earendil-works/pi-coding-agent

# 1. Clone this repo or use it as a GitHub template
git clone https://github.com/algoSiliguri/agent-os-starter my-project
cd my-project

# 2. Bootstrap everything (installs brain CLI + Agent OS Pi extension)
bash setup.sh

# 3. Check the install without opening an interactive Pi session
bash doctor.sh

# 4. Open Pi in your project
pi

# 5. Initialize (run once per project — no arguments needed)
> /init

# 6. Verify everything is working inside Pi
> /doctor

# 7. Start your first task
> /flow "create a hello world file"
```

`setup.sh` installs the `brain` CLI (via `uv`) and the Agent OS Pi extension. It requires `pi` to already be installed — it will fail with install instructions if not. Re-running it is safe — it skips already-installed components. `/init` with no arguments uses your folder name as the project ID. Re-running `/init` on an already-initialized project is safe.

Install and update targets are defined in `agent-os-install.env`. The current release config installs Agent OS from the immutable `v1.6.1` tag.

Lifecycle commands:

```bash
bash setup.sh --dry-run       # preview install
bash doctor.sh                # non-interactive health check
bash doctor.sh --release-check # verify release-source/version alignment
bash update.sh --dry-run      # preview update
bash update.sh                # update Agent OS + knowledge-brain
bash uninstall.sh --dry-run   # preview uninstall
bash uninstall.sh             # remove Agent OS from Pi, preserve project data
bash smoke-user-install.sh --i-understand-this-mutates-user-install --dry-run
```

Developer-only smoke tests stay separate from the user install path. From the sibling `Agent_OS` repo, run `npm run dev:smoke` to test local source in an isolated `PI_CODING_AGENT_DIR`.

---

## Primary workflow

`/flow` is the main entry point. It runs the full lifecycle (grill → plan → run → verify → review → evaluate) with guided prompts and approval gates at each step.

```
> /flow "add dark mode toggle to settings page"
```

`/flow` pauses at every gate. You answer questions, approve the plan, confirm execution, and review results. Use `/continue` to resume if the session is interrupted.

> **Warning:** `/run` (triggered by `/flow`) executes real shell commands inside your project directory.
> Review the plan before confirming at the approval gate.

---

## Power user — step by step

Run phases individually if you need direct control:

```
> /grill "create a hello world file"
> /plan
> /run
```

---

## Observe what happened

After any command, run `/flight` to see a timeline of what happened:

```
> /flight
```

Shows state transitions, steps, brain memory operations, and a health summary. A `report.md` is written to `.agent-os/runtime/sessions/{session_id}/` after each call.

---

## Persist memory

```
> /remember
git add data_store/knowledge.jsonl
git commit -m "save session memory"
```

`/remember` auto-exports to `data_store/knowledge.jsonl`. Commit that file to persist memory across machines.

---

## What is safe to run on a fresh machine

| Command | Side effects | Safe to run |
|---------|-------------|-------------|
| `/doctor` | none | yes |
| `/status` | none | yes |
| `/flight` | none | yes |
| `/grill <idea>` | writes local grill record | yes |
| `/diagnose` | writes diagnosis record | yes |
| `/quick-task` | writes quick-task record | yes, with escalation prompt |
| `/plan` | writes local plan, asks for approval | yes |
| `/run` | executes shell commands via Pi agent | yes, with demo plan |
| `/verify` | writes verification record | yes |
| `/review` | writes review record | yes |
| `/evaluate` | writes evaluation record | yes |
| `/remember` | writes to brain DB + exports jsonl | yes |
| `/flow <goal>` | runs full lifecycle grill→verify in one command | yes, pauses at each gate |
| `/continue` | resumes task from current state | yes |
| `/memory` | recovers pending memory candidates after interrupted /remember | yes |

---

## Advanced examples

See [brain_playground](https://github.com/agnivadc/brain_playground) for real-world integration patterns, governance traces, and advanced flows.
