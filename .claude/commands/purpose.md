# Purpose - Quick Documentation Update

**Fast, autonomous documentation update for routine development progress.**

---

## Autonomous Workflow

Analyze the recent conversation and any visible code changes to determine what was accomplished, then execute the following workflow WITHOUT asking questions (use best judgment):

---

## Step 1: Analyze Context (Silent)

Review recent messages to determine:
- What feature work was completed
- Any technical insights worth documenting
- Progress on current ROADMAP priority
- Any bugs fixed or patterns discovered

---

## Step 2: Update README.md (If Needed)

Update ONLY if:
- New feature adds to "Core Features"
- Getting started process changed
- Content management patterns added

**Most routine work does NOT need README updates.**

---

## Step 3: Update CLAUDE.md (Rarely)

Add ONLY if critical pattern discovered:
- Architectural pattern for reuse
- SwiftData gotcha
- Testing principle change

**Most routine work does NOT need CLAUDE updates.**

---

## Step 4: Update HISTORY.md (Always)

Add concise entry to current phase:

```markdown
**[Date]** - `[hash]` - [type]: [brief description]
- [Key accomplishment]
- [Metric if applicable]
```

**Keep it brief - this is routine progress.**

---

## Step 5: Update ROADMAP.md (Current Priority)

**Update current in-progress priority:**
- Mark completed tasks with ✅
- Update status if changed (Planned → In Progress, etc.)
- Update timeline if significantly different

**Do NOT mark priorities complete without user confirmation.**

---

## Step 6: Commit and Push (Automatic)

Generate concise commit message:

```
type(scope): brief description

[1-2 sentences of what changed]

Docs: Updated HISTORY.md, ROADMAP.md progress
```

Execute:
```bash
git add CLAUDE.md README.md HISTORY.md ROADMAP.md
git commit -m "[generated message]"
git push origin main

# Get commit hash and update HISTORY.md locally (don't commit)
COMMIT_HASH=$(git rev-parse --short HEAD)
# Edit HISTORY.md to replace placeholder with actual commit hash
# Leave this as LOCAL-ONLY change - it will be committed with next material update
```

**Important:** Update the commit hash in HISTORY.md but leave it as a local-only change. The hash update will go out with the next material documentation update.

---

## Output to User

Show brief summary:
```
✅ Documentation updated
   README.md: [updated/no changes]
   CLAUDE.md: [updated/no changes]
   HISTORY.md: [entry added]
   ROADMAP.md: [progress updated]

📝 Commit: [hash] - [message]
🚀 Pushed to origin/main
```

---

**Execute workflow now based on conversation context.**
