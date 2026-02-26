---
name: parallel-report
description: "Run parallel agents via the Task tool and automatically generate numbered report files in docs/agents/. Each agent's result becomes a structured markdown report."
---

# Parallel Agent Report Generator

## Overview

Execute multiple tasks simultaneously using parallel agents (Task tool), and save each agent's result as a **sequentially numbered report file** in the `docs/agents/` directory.

## Usage

```
/parallel-report <overall topic or goal> -- <task1> | <task2> | <task3> ...
```

If called without arguments, interactively ask the user for the task list.

## Execution Steps

### Step 1: Preparation

1. Create `docs/agents/` directory if it doesn't exist.
2. Check existing files to determine the next sequence number.
   - If no existing files, start from `000_`
   - If files exist, continue from the highest number + 1
3. If no arguments are provided, ask the user:
   - Overall topic/goal
   - List of individual tasks to run in parallel

### Step 2: Run Parallel Agents

Launch a Task tool agent for each task. **Prefer parallel execution** — launch all independent agents simultaneously in a single message. If tasks have dependencies (e.g., task B needs the output of task A), run them sequentially in dependency order.

Each agent prompt must include the following:

```
You are parallel research agent #{number}.

## Task
{Individual task description for this agent}

## Overall Context
{Overall topic/goal}

## Output Format
Return your results in the markdown format below. You MUST follow this format exactly:

---START_REPORT---
# {Task Title}

> Date: YYYY-MM-DD
> Agent: #{number}
> Status: Complete

## Summary
{2-3 line executive summary}

## Details
{Structured findings from research/analysis}

## Key Findings
{Bullet points of major discoveries}

## Recommendations
{Next steps or suggestions}

## References
{Files, URLs, or sources consulted}
---END_REPORT---
```

### Step 3: Generate Report Files

As each agent returns its result, create a file in `docs/agents/`.

**File Naming Convention:**
```
{3-digit sequence number}_{task-keyword}.md
```

Example:
```
docs/agents/
├── 000_architecture-analysis.md
├── 001_security-audit.md
├── 002_performance-review.md
└── 003_dependency-check.md
```

- Sequence numbers use 3-digit zero-padding (`000`, `001`, `002`, ...)
- Keywords are English kebab-case summaries of the task content (spaces to hyphens, lowercase)
- Extract content between `---START_REPORT---` and `---END_REPORT---` markers and save to file

### Step 4: Summary Report

Present the following to the user:
- List of generated report files
- One-line summary of each report's key findings

## Error Handling

- If an agent fails, mark that report file's status as `Failed` and log the error details.
- On partial failure, still generate reports for all successful agents.
- If `---START_REPORT---` / `---END_REPORT---` markers are missing, use the agent's entire response as the report body.

## Key Principles

- **Parallel preferred, sequential allowed** — Run independent tasks in parallel; use sequential execution when tasks have dependencies
- **Consistent numbering** — Continue sequence from existing file numbers
- **Structured output** — All reports follow the same markdown format
- **Fault tolerance** — Partial failures do not block successful results
