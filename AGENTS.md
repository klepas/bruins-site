# AGENTS.md

## Repository overview

This is the Jekyll-powered website for the philosopher Bruin Christensen and their writings, blog, and course materials.

The site is live published live to http://www.cbchristensen.net/.

The content is primarily in English, with some pages holding German-language content, either in part or in full as the main article body.

## Directory structure

TODO.

## Jekyll

TODO.

## Quick commands

TODO.

## Skills

On-demand references.

Invoke the one whose topic matches the task. Each skill is the single owner of its subject, and the AGENTS.md files carry only pointers to it.

| Skill | Use when |
| --- | --- |
| `antislop` | Writing or editing prose: Markdown docs (README, AGENTS.md) and in-code comments/docstrings. Suppresses AI writing tells; enforces plain English and punctuation rules. |

## Linting and formatting

TODO.

## Key technologies

TODO.

## Dependencies

TODO.

## Deployment

TODO.

## Git workflow

TODO.

## LLM contribution guidelines

1. **Do not run local dev servers**. Assume the user is already running them.
2. **Do not git commit changes on behalf of the user**. The user will make git commits. You can suggest commit messages.
3. **Always update** the relevant AGENTS.md when making structural changes.

## Updating this file

**IMPORTANT**: When making changes that affect the repository structure, dependencies, or workflows, update this AGENTS.md file and any subdirectory AGENTS.md files specific to those changes. This ensures future LLM sessions have accurate context.
