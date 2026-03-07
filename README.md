# AI Agent Orchestra

**A playbook for orchestrating multiple AI coding agents on a single codebase.**

Most companies hand their engineers an AI coding tool and say "be more productive." No playbook. No structure. No methodology. Engineers waste hours figuring out what to ask, how to scope prompts, and how to prevent the AI from making things worse.

This repo is the operating system I built to run multiple AI coding agents (Claude Code) in parallel on a real production codebase — as a solo founder. The same patterns work for teams of any size using any LLM coding tool.

**What's inside:**
- A structured "Ways of Working" document that turns AI coding from chaos into a repeatable process
- Role-based agent isolation so multiple agents can work in parallel without conflicts
- Communication protocol so agents coordinate through files, not conversation
- Scripts to set up, generate, and sync everything automatically

---

## Table of Contents

1. [The Problem](#the-problem)
2. [The Operating System](#the-operating-system)
3. [The Agent Orchestra](#the-agent-orchestra)
4. [How Agents Communicate](#how-agents-communicate)
5. [Quick Start](#quick-start)
6. [What's in This Repo](#whats-in-this-repo)
7. [Lessons Learned](#lessons-learned)
8. [FAQ](#faq)
9. [About](#about)

---

## The Problem

You open VS Code. You start Claude Code (or Copilot, or Cursor). You type: "Add authentication to my app."

The AI generates 400 lines of code. Half of it is wrong. It modified files you didn't want touched. It introduced a security vulnerability in the auth middleware. It didn't write tests. When you fix one thing, it breaks another.

Now multiply this by a team of engineers, each with their own AI sessions, all making changes to the same codebase. Nobody knows what anyone else's AI is doing.

**The root cause isn't the AI. It's the lack of structure around it.**

AI coding tools are extraordinarily capable. But they're stateless — every session starts from zero. They have no memory of decisions, no awareness of team norms, no understanding of your architecture. Without explicit structure, they default to generic patterns that may or may not fit your codebase.

The engineers struggling aren't bad engineers. They've just never been given a playbook.

---

## The Operating System

The core insight: **treat your AI coding agent like a new hire who has amnesia every morning.**

Every single session, the agent wakes up knowing nothing. You need to give it:
1. **Identity** — what is its role and scope?
2. **Rules** — how does this team work?
3. **Context** — what's the current state of work?
4. **Constraints** — what should it never touch?

This is codified in a `CLAUDE.md` file (or equivalent for your tool) that the agent reads on every startup. Not a suggestion. Not a "please consider this." A hard contract.

### The Brainstorm Gate

The single most impactful rule:

> **Before writing ANY code, the agent must present 2-3 options with trade-offs and wait for human approval.**

This one rule prevents 80% of AI coding disasters. Without it, the agent charges ahead with whatever approach it generates first — which is often plausible but wrong for your specific context.

The full workflow:
1. **Brainstorm** — Agent presents 2-3 options with trade-offs
2. **Agree** — Human picks one (or suggests a different approach)
3. **Plan** — Agent explores the codebase, writes a detailed plan, gets approval
4. **Implement** — Only after steps 1-3 does the agent write code

This adds ~5 minutes per task but saves hours of cleanup.

### Ways of Working Document

Your `CLAUDE.md` (or equivalent) should cover:

| Section | What It Does |
|---------|-------------|
| **Brainstorm gate** | Forces explore-before-commit pattern |
| **Git workflow** | Branch naming, PR process, merge rules |
| **Deployment rules** | What deploys where, safety checks |
| **Tracker discipline** | How work is tracked, status lifecycle |
| **Testing rules** | What needs tests, coverage expectations |
| **Crash recovery** | How to resume after a session dies mid-task |

See [templates/CLAUDE.md](templates/CLAUDE.md) for a complete example.

### Crash Recovery Protocol

AI sessions die. Context windows fill up. Laptops close. The agent is stateless, so when it comes back, it doesn't know what it was doing.

**The fix:** Update your tracker at every checkpoint.

```
Status: In Progress
Comments: "Code done. Tests passing. PR created (#47). Deployment pending."
```

When the next session starts, the agent reads the tracker, sees the in-progress item, and knows exactly where to pick up. No guessing. No re-doing work.

---

## The Agent Orchestra

When you need to move fast, one agent isn't enough. But multiple agents on the same codebase is a recipe for merge conflicts and duplicated work.

**Solution: Give each agent a role with non-overlapping scope.**

### Architecture

```
Your GitHub Repo (single monorepo)
        |
        |--- git clone x N
        |
./agents/fullstack/     -> CLAUDE.md = Fullstack role
./agents/web/           -> CLAUDE.md = Web/DevRel role
./agents/infra/         -> CLAUDE.md = DevOps role
./agents/architect/     -> CLAUDE.md = Architect role
```

Each agent gets:
- Its own git clone of the same repo
- A role-specific `CLAUDE.md` at the repo root
- A defined scope (which directories it can modify)
- A startup protocol (what to do when the session starts)

### Example Roles

| Role | Scope (can modify) | Scope (read-only) | Branch Prefix |
|------|-------------------|-------------------|---------------|
| **Architect** | Entire codebase | — | `arch/` |
| **Fullstack** | `src/server/`, `src/client/`, `sdks/` | Everything else | `fullstack/` |
| **Web/DevRel** | `src/website/`, `demos/` | Everything else | `web/` |
| **DevOps** | `infra/` | Everything else | `infra/` |

**Why these roles?** The key constraint is **non-overlapping directory scope**. If two agents can modify the same files, you get merge conflicts. Design roles so their `Scope (can modify)` columns don't overlap.

**Maximum parallelism = number of non-overlapping scopes.** In this example: 3 agents simultaneously (fullstack + web + infra). The architect coordinates but doesn't run in parallel with implementation agents.

### Why Monorepo (Not Polyrepo)

| | Monorepo + multiple clones | Polyrepo |
|---|---|---|
| Shared types | One commit updates everything | Publish package, update consumers |
| Refactoring | One grep across everything | Hunt across N repos |
| Agent isolation | Enforced by CLAUDE.md rules | Enforced by repo boundary |
| Setup | `git clone` x N | Separate repos, package registry |

CLAUDE.md scope rules are "soft" boundaries (the agent *could* violate them, but won't because it reads the rules). This is sufficient for AI agents — they follow instructions reliably. You don't need hard repo boundaries.

### How CLAUDE.md Is Generated

Each clone's `CLAUDE.md` is generated by concatenating two files:

```
docs/roles/base.md      +  docs/roles/fullstack.md  =  agents/fullstack/CLAUDE.md
(shared rules)             (role-specific profile)      (what the agent reads)
```

This means:
- Change a shared rule in `base.md` → all agents get it on next pull
- Change a role profile → only that agent is affected
- Everything is version-controlled in the main repo

### Self-Sufficient Agents

Each clone has a git `post-merge` hook that auto-regenerates `CLAUDE.md` after every `git pull`:

```bash
#!/bin/bash
ROLE="fullstack"
if [[ -f "docs/roles/base.md" && -f "docs/roles/$ROLE.md" ]]; then
    cat "docs/roles/base.md" "docs/roles/$ROLE.md" > CLAUDE.md
fi
```

No manual sync needed. Pull = updated rules.

---

## How Agents Communicate

Agents can't talk to each other. They're separate processes in separate VS Code windows. So how do they coordinate?

**Three mechanisms:**

### 1. Tracker as Task Queue

A simple CSV (or your preferred project tracker) is the task queue:

```
ID,Priority,Category,Title,Status,Assigned To
FEAT-001,P1,Platform,Add auth middleware,Ready,
FEAT-002,P1,Marketing,Update pricing page,Ready,
FEAT-003,P0,Infra,CloudWatch alarms,Ready,
```

Each agent's startup protocol includes: *"Read the tracker. Filter for Ready items in your scope. Propose the top 3 you'd work on."*

The human picks one. The agent starts working. No scheduling system needed.

### 2. Design Docs as Message Bus

Every feature has a design doc (`docs/design/FEAT-001.md`). It includes an **Agent Notes** section:

```markdown
## Agent Notes
- [2026-02-22 fullstack] Implemented API routes. New response type in types.ts — web agent should update demo app.
- [2026-02-22 architect] Reviewed PR #47. Missing rate limiting — created FEAT-004.
- [2026-02-23 web] Updated demo app to use new API response shape.
```

This is how agents leave messages for each other. It's asynchronous, persistent, and version-controlled.

### 3. Human as Router

The human (you) is the orchestrator:
- Curate the tracker (set priorities, mark items Ready)
- Review PRs (every agent PR needs human approval)
- Resolve cross-scope dependencies ("fullstack needs an infra change — let me tell the infra agent")
- Merge and deploy

**Why not automate this?** At 3-4 agents, the overhead of a coordination system exceeds its benefit. The human is already the bottleneck (reviewing PRs, making product decisions). Building orchestration tooling solves a problem that doesn't exist yet.

**When to reconsider:** If you're running 6+ agents daily and human routing becomes the bottleneck, then build orchestration. Not before.

---

## Quick Start

### Prerequisites
- Git
- A GitHub repo (or any git remote)
- Claude Code, Copilot, Cursor, or any AI coding tool that reads a project config file

### 1. Copy the templates

```bash
# Copy template files into your repo
cp -r templates/docs/roles/ your-repo/docs/roles/
cp templates/CLAUDE.md your-repo/CLAUDE.md
cp -r templates/scripts/ your-repo/scripts/
chmod +x your-repo/scripts/*.sh
```

### 2. Customize

Edit `docs/roles/base.md` with your team's actual rules:
- Your git workflow (branch naming, PR process)
- Your deployment process
- Your testing requirements
- Your tracker format

Edit each role file (`docs/roles/fullstack.md`, etc.):
- Adjust scope to match your directory structure
- Set responsibilities that match your actual roles
- Customize the startup protocol

### 3. Set up agent clones

```bash
cd your-repo
./scripts/setup-agents.sh
```

This creates `./agents/{role}/` for each role, each with a role-specific `CLAUDE.md`.

### 4. Add to .gitignore

```
agents/
```

The agent clones are local working directories — don't commit them.

### 5. Start a session

1. Open VS Code on `./agents/fullstack/`
2. Start your AI coding tool
3. The agent reads `CLAUDE.md` and self-identifies
4. It follows the startup protocol: pull latest, check tracker, propose work

---

## What's in This Repo

```
ai-agent-orchestra/
├── README.md                          # You're reading this
├── templates/
│   ├── CLAUDE.md                      # Base ways-of-working (copy to your repo root)
│   ├── docs/
│   │   └── roles/
│   │       ├── base.md                # Shared rules (all agents get this)
│   │       ├── architect.md           # Architect role profile
│   │       ├── fullstack.md           # Fullstack role profile
│   │       ├── web.md                 # Web/DevRel role profile
│   │       └── infra.md              # DevOps role profile
│   ├── tracker.csv                    # Example task tracker
│   ├── design-doc-template.md         # Example design doc structure
│   └── scripts/
│       ├── setup-agents.sh            # One-time: clone repo per role
│       ├── generate-claude-md.sh      # Generate CLAUDE.md from base + role
│       └── sync-agents.sh             # Manual sync (backup for git hooks)
└── LICENSE
```

### Customization Guide

**Start minimal.** You don't need all 4 roles on day one. Start with:
1. Copy `base.md` as your `CLAUDE.md`
2. Add the brainstorm gate rule
3. Use it for a week
4. When you're ready for parallel agents, add roles

**Adapt to your tool.** This repo uses `CLAUDE.md` (Claude Code's project file). Other tools:
- **Cursor:** `.cursorrules`
- **Copilot:** `.github/copilot-instructions.md`
- **Windsurf:** `.windsurfrules`
- **Generic:** Any file your tool reads on startup

**Adapt to your stack.** The example roles assume a typical web app (server + client + marketing site + infra). Adjust to your architecture:
- Mobile app? Replace `web` with `mobile`
- ML pipeline? Add a `data` role for `notebooks/` and `pipelines/`
- Microservices? One role per service boundary

---

## Lessons Learned

### What worked immediately
- **The brainstorm gate** — prevents 80% of "AI did something stupid" incidents
- **Crash recovery via tracker** — sessions die constantly; having state in a file means zero re-work
- **Role-specific CLAUDE.md** — agents genuinely behave differently when given identity and scope
- **Design docs as message bus** — async communication that's automatically version-controlled

### What we got wrong first
- **Started with 5 roles, consolidated to 4** — separate Backend and Frontend agents created unnecessary handoffs. Most features touch both server and client. A Fullstack agent handles both sides in one PR.
- **Started with manual sync, moved to git hooks** — forgot to sync CLAUDE.md after pulling new rules. Post-merge hooks solved it automatically.
- **Agent clones in home directory** — created `~/agents/` initially, should have been `./agents/` relative to the project. Keep everything colocated.
- **Tried to build orchestration** — considered a coordinator process, message queues, etc. Completely unnecessary at 3-4 agents. The tracker IS the orchestration.

### Counter-intuitive insights
- **The human is the bottleneck, not the agents.** You'll run out of PR review capacity before you run out of agent capacity. 3 parallel agents is the practical max for one human reviewer.
- **Agents follow rules better than humans.** Once you put "never deploy without human approval" in CLAUDE.md, the agent NEVER deploys without approval. Humans forget. Agents don't.
- **More structure = more speed.** The brainstorm gate feels slow. The startup protocol feels ceremonial. But they prevent the 2-hour debugging sessions that happen when the agent charges ahead without context.
- **Statelessness is a feature.** Every session is a clean start. No accumulated bad habits, no grudges about yesterday's code review, no "but we always do it this way." Fresh eyes every time.

---

## FAQ

**Q: Does this only work with Claude Code?**
No. The patterns (role isolation, brainstorm gate, tracker discipline, crash recovery) work with any LLM coding tool. The specific file (`CLAUDE.md`) is Claude Code's convention — replace with `.cursorrules`, `.github/copilot-instructions.md`, or equivalent.

**Q: How many agents can run in parallel?**
As many as you have non-overlapping directory scopes. Practically, 3-4 for a solo operator (you'll hit PR review bottleneck). For teams, each person can run 2-3 agents.

**Q: Won't agents violate their scope boundaries?**
Rarely. AI coding tools follow explicit instructions reliably. If your CLAUDE.md says "NEVER modify `infra/`", the agent won't. If it does (very rare), the PR review catches it.

**Q: Do agents need to be on the same machine?**
No. Each agent is a separate git clone pointing to the same remote. They can be on different machines, different CI runners, or different team members' laptops.

**Q: What if two agents create conflicting changes?**
The role design prevents this — non-overlapping scopes mean non-overlapping files. For shared files (like a tracker or changelog), one role owns them and others only update their own rows.

**Q: Is this just micromanaging the AI?**
No. This is giving the AI the context it needs to be autonomous. Without structure, you micromanage every response ("no, not that file", "no, use the other pattern"). With structure, you say "do FEAT-001" and walk away.

---

## About

Built by [Sanat Dhir](https://github.com/skdhir) while building a real product as a solo founder with AI coding agents. The patterns in this repo were developed over weeks of daily use, not theorized in a blog post.

**Results:** 120+ PRs merged, 100+ tracker items managed, 3 agents running in parallel — all orchestrated by one person.

If this helped you, star the repo and share it with your team. The engineering community needs practical playbooks, not more "AI will change everything" think pieces.

---

## License

MIT — use it however you want.

## Author

Sanat Dhir — [LinkedIn](https://www.linkedin.com/in/skdhir/) | [Medium](https://medium.com/@skdhir) | [GitHub](https://github.com/skdhir)

*Engineering leader. 20+ years building distributed systems. Columbia Executive MBA. Building and writing about AI-augmented software development.*
