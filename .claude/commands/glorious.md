# Glorious Documentation Update

**A comprehensive documentation workflow for significant milestones and major changes.**

---

## Step 1: Gather Context

Ask the user the following questions:

**What changed?**
- What feature/priority was completed or significantly advanced?
- What functionality was added, modified, or removed?

**Technical insights?**
- Were there any critical patterns, architectural decisions, or breakthroughs?
- Any bugs discovered and fixed?
- Performance improvements or optimizations?

**ROADMAP impact?**
- Should this mark a priority as COMPLETE (requires user confirmation)?
- Or update progress on current priority?
- Any blockers or timeline changes?

**Breaking changes?**
- Any changes that affect how developers use the codebase?
- New dependencies or requirements?

**Wait for user's complete response before proceeding to Step 2.**

---

## Step 2: Update README.md

Review README.md and update ONLY if changes affect developers:

**Update if:**
- ✅ New feature added to "Core Features"
- ✅ Architecture patterns changed
- ✅ New content type requires documentation
- ✅ Getting started process changed
- ✅ Build/test workflow modified

**Skip if:**
- ❌ Internal refactoring only
- ❌ Bug fixes with no user-facing impact
- ❌ Routine feature implementation

**Show proposed README.md changes to user before applying.**

---

## Step 3: Update CLAUDE.md

Add to CLAUDE.md ONLY if it meets **critical pattern** criteria:

**Add if:**
- ✅ New architectural pattern (like "Fetch All → Filter In-Memory")
- ✅ Critical bug pattern that MUST be avoided in future
- ✅ Testing principle that changes testing approach
- ✅ Workflow improvement affecting all future development
- ✅ SwiftData gotcha or performance pattern

**Do NOT add:**
- ❌ Routine feature implementations
- ❌ One-off fixes
- ❌ Temporary workarounds

**Format for new patterns:**
```markdown
### [N]. [Pattern Name]

**Context:** [When/why this matters]

[Code example with ✅ CORRECT and ❌ WRONG patterns]

**WHY:** [Explanation]

**WHEN TO USE:** [Clear guidance]
```

**Show proposed CLAUDE.md changes to user before applying.**

---

## Step 4: Update HISTORY.md

Add entry to the appropriate section in HISTORY.md:

**If current phase (Phase 7+):**
Find or create section for current development phase, add:

```markdown
**[Date]** - `[commit hash will be added after commit]` - [Brief Title]
- [What changed]
- [Why it matters]
- [Key metrics if applicable]
- [Bugs fixed if applicable]
```

**Format examples:**
```markdown
**Nov 3, 2025** - `abc1234` - feat: Complete onboarding system with interactive tours
- Implemented welcome flow with 5 feature-specific tours
- Added TourCoordinator pattern for tour management
- User testing shows 90% completion rate (target: 90%)
- Addresses critical user feedback: "Not clear how to use app"
```

**Show proposed HISTORY.md entry to user before applying.**

---

## Step 5: Update ROADMAP.md

### If Priority COMPLETE (user confirmed):

1. **Move to HISTORY.md:**
   - Copy priority description to HISTORY.md "Completed Features" section
   - Include completion date, key metrics, success criteria met

2. **Remove from ROADMAP.md:**
   - Delete completed priority section entirely

3. **Renumber priorities:**
   - Shift all remaining priorities up (Priority 2 → Priority 1, etc.)

4. **Update "Current State Assessment":**
   - Add completed feature to "Production Ready" list
   - Update technical health metrics if applicable

### If Updating Progress:

**Update status:**
- Planned → In Progress → Testing → Complete

**Update checkboxes:**
- Mark completed tasks with ✅
- Add new tasks discovered during development

**Update timeline:**
- Adjust estimates based on actual progress
- Note blockers if any

**Show proposed ROADMAP.md changes to user before applying.**

---

## Step 6: Generate Commit Message

Create commit message following this format:

```
type(scope): brief description (max 50 chars)

Detailed description of what changed and why.
Can be multiple paragraphs explaining context.

Key insights or decisions made.

Breaking changes (if any).

Documentation updates:
- README.md: [what changed]
- CLAUDE.md: [what changed or "no changes"]
- HISTORY.md: [entry added]
- ROADMAP.md: [progress updated or priority completed]
```

**Types:** feat, fix, docs, test, refactor, perf, chore

**Show commit message to user and ask for approval before proceeding.**

---

## Step 7: Commit and Push

After user approves commit message:

```bash
# Stage documentation files
git add CLAUDE.md README.md HISTORY.md ROADMAP.md

# Commit with approved message
git commit -m "[approved message]"

# Get commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)

# Update HISTORY.md with commit hash
# (edit the entry we just added to include the hash)
git add HISTORY.md
git commit --amend --no-edit

# Push to origin
git push origin main
```

**Show user confirmation of successful push.**

---

**Now begin Step 1: Gather context from the user.**
