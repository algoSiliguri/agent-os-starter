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
# 1. Clone this repo or use it as a GitHub template
git clone https://github.com/algoSiliguri/agent-os-starter my-project
cd my-project

# 2. Bootstrap everything (installs brain CLI + Agent OS Pi extension)
bash setup.sh

# 3. Open Pi in your project
pi

# 4. Initialize (run once per project — no arguments needed)
> /init

# 5. Verify everything is working
> /doctor
```

`setup.sh` installs the `brain` CLI (via `uv`) and the Agent OS Pi extension. Re-running it is safe — it skips already-installed components. `/init` with no arguments uses your folder name as the project ID. Re-running `/init` on an already-initialized project is safe.

---

## Safe demo (run this first)

```
> /grill "create a hello world file"
> /plan
> /run
```

> **Warning:** `/run` executes real shell commands inside your project directory.
> The included demo plan only creates `hello.txt` and runs `pwd`. Review the plan before confirming.

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

---

## Advanced examples

See [brain_playground](https://github.com/agnivadc/brain_playground) for real-world integration patterns, governance traces, and advanced flows.
