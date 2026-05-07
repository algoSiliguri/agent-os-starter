# agent-os-starter

Local governed AI agent for your project. Runs in [Pi](https://pi.ai) via the Agent OS extension.

**What it installs:** Pi extension + local knowledge DB (SQLite, project-local)
**What it writes:** `.agent-os/` (runtime, gitignored) · `data_store/knowledge.db` (gitignored) · `data_store/knowledge.jsonl` (committed)
**What it does not do:** network calls during normal use · write outside your project directory · auto-approve dangerous commands

---

## Prerequisites

- [Pi](https://pi.ai) installed and on PATH
- Node.js 20+
- `curl` (for uv install)
- `ANTHROPIC_API_KEY` set in your shell

---

## Start

```bash
# 1. Clone this repo or use it as a GitHub template
git clone https://github.com/agnivadc/agent-os-starter my-project
cd my-project

# 2. Run setup (checks deps, installs brain CLI, inits local DB)
bash setup.sh

# 3. Install Agent OS extension into Pi
pi install git:github.com/algoSiliguri/Agent_OS@v1.1.0

# 4. Open Pi in your project
pi

# 5. Initialize governance (press Enter to accept defaults)
> /init my-project

# 6. Verify — read-only, changes nothing
> /doctor
> /status
```

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

## Brain DB

Defaults to `./data_store/knowledge.db` (project-local).

To share memory across projects:
```bash
export BRAIN_DB_PATH="$HOME/.knowledge-brain/knowledge.db"
```

---

## Advanced examples

See [brain_playground](https://github.com/agnivadc/brain_playground) for real-world integration patterns, governance traces, and advanced flows.
