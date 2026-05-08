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

# 2. Install Agent OS extension into Pi (one time, global)
pi install git:github.com/algoSiliguri/Agent_OS@v1.2.0

# 3. Open Pi in your project
pi

# 4. Initialize (run once per project — no arguments needed)
> /init

# 5. Verify everything is working
> /doctor
```

`/init` with no arguments uses your folder name as the project ID. It installs the brain CLI, creates the local knowledge DB, and sets up governance files. Re-running `/init` on an already-initialized project is safe.

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
| `/grill <idea>` | writes local grill record | yes |
| `/plan` | writes local plan, asks for approval | yes |
| `/run` | executes shell commands via Pi agent | yes, with demo plan |
| `/remember` | writes to brain DB + exports jsonl | yes |

---

## Advanced examples

See [brain_playground](https://github.com/agnivadc/brain_playground) for real-world integration patterns, governance traces, and advanced flows.
