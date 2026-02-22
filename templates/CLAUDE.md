# Project — Ways of Working

## CRITICAL — Read Before Every Task

**STOP. Before writing ANY code, you MUST complete this checklist:**

1. **Brainstorm**: Present 2-3 options with trade-offs. Push back, challenge ideas, and advocate for the best solution.
2. **Agree**: Wait for the human to pick an option or suggest a different one.
3. **Plan**: Explore the codebase, write a detailed plan, and get explicit approval.
4. **Implement**: Only after steps 1-3 are done, start writing code.

If you find yourself editing a file without having brainstormed and planned **in this session**, STOP and go back to step 1.

**Exception — trivial changes** (typo fixes, single-label updates, docs-only edits) can skip brainstorming.

---

## Git & PR Workflow

5. **Branch per change off `dev`**: Every fix or feature gets a new branch off `dev`. Delete branch after merge. Never commit directly to `dev`.
6. **PR workflow**: Create branch -> code changes -> update tracker + design doc -> commit -> push -> create PR -> review -> merge.
7. **Commit messages**: Clear, concise, explain the "why". Include the ticket ID.
8. **Promoting to `main`**: Merge `dev` -> `main` before demos, milestones, or after 5+ verified features.

## Tracker Discipline

The tracker (`tracker.csv`) is the single source of truth for all work.

### Row Lifecycle

| Status | Meaning |
|--------|---------|
| `New` | Filed but not refined |
| `Ready` | Requirements agreed, ready to pick up |
| `In Progress` | Actively being worked on |
| `Done` | Completed and verified |
| `Backlog` | Known need, not prioritized |
| `Parked` | Deliberately shelved |

### Crash Recovery

9. **Set "In Progress" before starting work**: Update tracker before writing code.
10. **Update tracker at each checkpoint**: For multi-step tasks, note completed steps in Comments.
11. **Only set "Done" after verification**: Not until the PR is merged and changes are verified.
12. **On session start, check for "In Progress" items**: Investigate what was completed vs. missing.

### Design Docs

13. **Every non-trivial item gets a design doc**: `docs/design/{ID}.md` captures the why and how.
14. **Create design doc at the START of brainstorming**: Write findings before presenting to the human. If the session crashes, research is recoverable.

## Testing

15. **Write tests for everything**: Every feature and bug fix must include tests. No PR ships without test coverage.

## Agent Communication

16. **Agents communicate through files, not conversation**: Use design doc Agent Notes and tracker Comments.
17. **Agent Notes format**: `- [YYYY-MM-DD {role}] {note}` — append to design doc `## Agent Notes` section.
18. **If blocked, create a tracker item**: Note the blocker and what you need from another role.
19. **Agents NEVER merge without human review**: Create a PR and wait.
20. **Agents NEVER deploy to production**: Only the human deploys.
