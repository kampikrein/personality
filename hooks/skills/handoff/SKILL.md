---
name: handoff
description: Write or update a handoff document so the next agent with fresh context can continue this work.
---

# Handoff

Write or update a handoff document so the next agent with fresh context can continue this work.

## Steps

1. **Check if HANDOFF.md already exists** in the project root.
2. **If it exists, read it first** to understand prior context before updating.
3. **Create or update** the document with the following sections:

### HANDOFF.md Structure

```markdown
# Handoff

## Goal
What we're trying to accomplish.

## Current Progress
What's been done so far.

## What Worked
Approaches that succeeded.

## What Didn't Work
Approaches that failed (so they're not repeated).

## Next Steps
Clear action items for continuing.
```

4. **Save as `HANDOFF.md`** in the project root.
5. **Tell the user the file path** so they can start a fresh conversation with just that path.

## Guidelines

- Be concise but thorough — the next agent has zero prior context.
- Focus on actionable information: what to do next, not a full history.
- Include specific file paths, commands, or error messages that are relevant.
- If updating an existing HANDOFF.md, preserve useful prior context and merge new information.
- The "What Didn't Work" section is critical — it prevents the next agent from repeating failed approaches.
