# AGENTS.md

## Repository overview

This is the Jekyll-powered website for the philosopher Bruin Christensen (Carleton B. Christensen) and their writings, blog, and course materials.

The site is live at http://www.cbchristensen.net/.

The content is primarily in English, with some pages holding German-language content, either in part or in full as the main article body.

A rebuild is in progress on the `site-rebuild-with-latest-jekyll-and-new-theme` branch: a current Ruby, the latest Jekyll, a new theme, and all content brought back with unchanged URLs. Read [`plans/overview-site-rebuild.md`](./plans/overview-site-rebuild.md) before working on any part of it. `plans/` is gitignored, so the plans only exist on the user's machine.

## Directory structure

During the rebuild:

```
.
├── AGENTS.md          Agent instructions (CLAUDE.md points here)
├── .claude/skills/    Project skills, see Skills below
├── plans/             Plan sets, one folder each (only AGENTS.md and CLAUDE.md are committed)
│   └── done/          Finished plan sets
└── refs/old-site/     The old Jekyll 2 site, a read-only reference
```

The new site gets built at the repo root. Content goes back to the paths it had in the old site: `papers/_posts/`, `blog/_posts/`, the `_descartes/`, `_dilthey/` and `_technology/` collections, `files/`, and the top-level pages. Update this section as files land.

## Jekyll

The old site ran Jekyll 2.5.3. The rebuild moves to Jekyll 4.4.1, see `plans/install-latest-jekyll/install-latest-jekyll-00-overview.md`.

- **Never change a published URL.** Every page, paper, course document and file keeps its exact live path. `plans/live-url-inventory.tsv` lists all of them. Jekyll 4 builds course and some paper URLs differently from Jekyll 2, and the overview plan explains how to pin them.
- Keep `refs/` and `plans/` in the `exclude:` list in `_config.yml`. Otherwise Jekyll builds the old site's pages over the new ones.

## Quick commands

TODO. The Ruby and Jekyll plans fill this in.

## Skills

On-demand references.

Invoke the one whose topic matches the task. Each skill is the single owner of its subject, and the AGENTS.md files carry only pointers to it.

| Skill | Use when |
| --- | --- |
| `antislop` | Writing or editing prose: Markdown docs (README, AGENTS.md) and in-code comments/docstrings. Suppresses AI writing tells; enforces plain English and punctuation rules. |

## Linting and formatting

TODO.

## Key technologies

- Ruby, managed locally with rbenv. The rebuild pins it in `.ruby-version` (3.4 planned).
- Jekyll, with kramdown for Markdown and Liquid for templates.
- AWS S3 static website hosting.

## Dependencies

Keep them few. The site has to keep building in CI for years with little upkeep. Ask the user before adding any gem, plugin or theme, and give each one in the Gemfile a comment saying why it's there. No Node toolchain, and no third-party CDNs in the pages.

## Deployment

The live site is served from the S3 bucket `www.cbchristensen.net` (`ap-southeast-2`) over HTTP. A separate nginx host redirects `cbchristensen.net` to `www.`. The last deploy happened on 2022-04-19, and the repo doesn't record how. Don't attempt a deploy.

TODO: document the deploy process once it's decided.

## Git workflow

- `master` is the default branch and holds the published content. Bruin edits content directly on `master` through GitHub's web editor.
- Rebuild work happens on `site-rebuild-with-latest-jekyll-and-new-theme`.

## LLM contribution guidelines

1. **Do not run local dev servers**. Assume the user is already running them. That includes `jekyll serve`.
2. **Do not git commit changes on behalf of the user**. The user will make git commits. You can suggest commit messages.
3. **Always update** the relevant AGENTS.md when making structural changes.
4. **Treat `refs/old-site/` as read-only**. Copy content out of it, never edit it in place.
5. **Keep plans current**. For rebuild work, read `plans/overview-site-rebuild.md` first, follow the conventions in `plans/AGENTS.md`, and log progress in the plan set you're working from.

## Updating this file

**IMPORTANT**: When making changes that affect the repository structure, dependencies, or workflows, update this AGENTS.md file and any subdirectory AGENTS.md files specific to those changes. This ensures future LLM sessions have accurate context.
