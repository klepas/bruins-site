# AGENTS.md - Plans Directory

## Purpose

This directory contains structured migration and project plans broken into incremental, self-contained tasks. Each plan set follows a consistent format so that any LLM agent (or developer) can pick up a task and execute it independently.

## How plans are organized

A plan set consists of:

- **`<name>-00-overview.md`** -- Motivation, full scope, component/file mapping, cross-cutting concerns, and a dependency graph of all tasks.
- **`<name>-XX-<taskname>.md`** -- Individual tasks numbered in recommended execution order. Each is scoped to be completable in a single focused session.

Tasks may declare dependencies on other tasks (e.g., "Depends on: 01-setup"). Independent tasks can be worked on in parallel.

## Writing a new plan set

When the user asks you to plan a large migration, refactor, or multi-step project, create files in this directory following the conventions below.

### Overview file (`00-overview`)

Must include:

1. **Motivation** -- Why this work is being done. What problem does it solve or what does it improve?
2. **Scope** -- Which files, packages, and systems are affected. Be explicit with file paths.
3. **Mapping table** -- If replacing one thing with another (library, pattern, API), include a table mapping old to new with notes on key differences.
4. **Cross-cutting changes** -- Patterns that apply across many tasks (e.g., data attribute renames, CSS variable changes, import path changes).
5. **Task breakdown table** -- A table listing every task with its ID, description, and dependencies.
6. **Reference material** -- Links to docs, migration guides, reference implementations, and relevant discussions.

### Task files (`XX-taskname`)

Each task file must include:

1. **Goal** -- One sentence describing what this task accomplishes.
2. **Depends on** -- Links to prerequisite tasks (or "none").
3. **Files to change** -- Explicit list of file paths that will be modified.
4. **Migration details** -- Specific instructions for each file:
   - Old import / new import
   - Sub-component mapping tables where applicable
   - Data attribute changes
   - CSS variable changes
   - Structural changes with before/after code snippets
   - Pitfalls or gotchas to watch for
5. **Acceptance criteria** -- A checklist of verifiable outcomes:
   - Build passes
   - Formatting and linting pass (once we install this)
   - Old dependencies removable (with grep verification)

### Sizing tasks

- Each task should be **completable in one session** by a mid-level developer (or a single LLM agent invocation).
- Group related files that share the concern.
- Setup and cleanup are always separate tasks.

### Naming conventions

```text
<project-name>-00-overview.md
<project-name>-01-setup.md
<project-name>-02-<descriptive-name>.md
...
<project-name>-XX-cleanup.md
```

Use lowercase with hyphens. Numbers are zero-padded to two digits. The last task should always be cleanup/verification.

## Executing a task

When asked to execute a task from this directory:

1. **Read the overview first** (`00-overview`) to understand the full context.
2. **Read the specific task file** to understand exact requirements.
3. **Check dependencies** -- verify prerequisite tasks are complete (e.g., grep for old imports that should have been removed).
4. **Make the changes** following the migration details precisely.
5. **Run acceptance criteria** -- execute the verification commands listed in the task.
6. **Do not run dev servers** -- assume the user has them running. Verify via static analysis only.
7. **Update the overview** if you discover something that affects other tasks (new gotchas, dependency changes).

## Conventions

- Plans are **living documents** -- update them when you discover new information during execution.
- If a task turns out to be larger than expected, split it and update the overview's task table.
- If a task becomes unnecessary (e.g., the API turns out to be identical), mark it as skippable in the overview and note why.
- Cross-reference between tasks using relative markdown links.
