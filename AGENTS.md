# AGENTS.md

## Repository overview

This is the Jekyll-powered website for the philosopher Bruin Christensen (Carleton B. Christensen) and their writings, blog, and course materials.

The site is live at http://www.cbchristensen.net/.

The content is primarily in English, with some pages holding German-language content, either in part or in full as the main article body. Bruin writes Australian and British English, so use that spelling in any interface text you write. The site's `lang` is `en-AU`, and only pages written entirely in German get `lang: de`. The interface stays English on those pages.

A rebuild is in progress on the `site-rebuild-with-latest-jekyll-and-new-theme` branch: a current Ruby, the latest Jekyll, a new theme, and all content brought back with unchanged URLs. Read [`plans/overview-site-rebuild.md`](./plans/overview-site-rebuild.md) before working on any part of it. `plans/` is gitignored, so the plans only exist on the user's machine.

## Directory structure

During the rebuild:

```
.
├── AGENTS.md          Agent instructions (CLAUDE.md points here)
├── Gemfile            Ruby gems for the site, see Dependencies below
├── Gemfile.lock       Resolved gem versions for every platform
├── _config.yml        Jekyll config
├── _includes/         head, header and footer, from Minima 2.5.2
├── _layouts/          base, page, post and home, from Minima 2.5.2
├── _sass/             Minima's Sass, with its MIT licence in _sass/minima/LICENSE.txt
├── assets/main.scss   Compiles to assets/main.css
├── style-guide/       Theme test pages, published: false, built with --unpublished
├── .claude/skills/    Project skills, see Skills below
├── plans/             Plan sets, one folder each (only AGENTS.md and CLAUDE.md are committed)
│   └── done/          Finished plan sets
└── refs/old-site/     The old Jekyll 2 site, a read-only reference, deleted before the merge to master
```

The new site gets built at the repo root. Content goes back to the paths it had in the old site: `papers/_posts/`, `blog/_posts/`, the `_descartes/`, `_dilthey/` and `_technology/` collections, `files/`, and the top-level pages. Update this section as files land.

## Jekyll

The site runs Jekyll 4.4.1, the newest stable release as of 2026-10-18. The old site ran Jekyll 2.5.3. See `plans/done/install-latest-jekyll/install-latest-jekyll-00-overview.md` for the install.

- **Never change a published URL.** Every page, paper, course document and file keeps its exact live path. `plans/live-url-inventory.tsv` lists all of them. Jekyll 4 builds course and some paper URLs differently from Jekyll 2, and the overview plan explains how to pin them.
- Keep `refs/` and `plans/` in the `exclude:` list in `_config.yml`. Otherwise Jekyll builds the old site's pages over the new ones. Jekyll 4 adds its own defaults (`Gemfile`, `Gemfile.lock`, `vendor/bundle/` and so on), so don't repeat them.
- `url` is the canonical host, `http://www.cbchristensen.net`. `jekyll doctor` warns and exits with status 1 without it.
- `timezone: UTC` matches the 2022 build, so every front matter date lands on the same day in its URL.
- `permalink: date` is Jekyll 4's default. Writing it down protects the paper URLs if a future Jekyll changes the default.
- Don't remove `timezone` or `permalink` without re-running the URL parity check in the rebuild overview.

## Quick commands

Run from the repo root.

- `rbenv install`: installs the Ruby named in `.ruby-version`. Use it on a new machine.

- `bundle install`: installs the gems in `Gemfile.lock`.
- `bundle exec jekyll build`: builds the site into `_site/`.
- `bundle exec jekyll doctor`: checks the config and content for problems. It should print "Everything looks fine."

`bundle exec jekyll serve` is the user's to run. Don't start it.

## Skills

On-demand references.

Invoke the one whose topic matches the task. Each skill is the single owner of its subject, and the AGENTS.md files carry only pointers to it.

| Skill | Use when |
| --- | --- |
| `antislop` | Writing or editing prose: Markdown docs (README, AGENTS.md) and in-code comments/docstrings. Suppresses AI writing tells; enforces plain English and punctuation rules. |

## Linting and formatting

TODO.

## Key technologies

- Ruby, managed locally with rbenv. Ruby 3.4.11, pinned in `.ruby-version`.
- Jekyll 4.4.1, with kramdown for Markdown and Liquid for templates.
- AWS S3 static website hosting.

## Dependencies

Keep them few. The site has to keep building in CI for years with little upkeep. Ask the user before adding any gem, plugin or theme, and give each one in the Gemfile a comment saying why it's there. No Node toolchain, and no third-party CDNs in the pages.

The Gemfile lists three gems:

- `jekyll` (`~> 4.4.1`).
- `bigdecimal`. Liquid 4.0.4 requires it without declaring it, and Ruby 3.4 dropped it from the default gems.
- `logger`. Jekyll 4.4.1 requires it without declaring it, and Ruby 4.0 drops it from the default gems.

Today both of the last two reach the bundle through other gems. Declaring them keeps the build working if those chains change.

`Gemfile.lock` keeps every platform Bundler writes into a new lockfile, about 19 of them plus `ruby`. Don't add or remove platforms. If `PLATFORMS` shows only `ruby`, check `~/.bundle/config` for `force_ruby_platform`.

Dependabot security updates are on in the repo's GitHub settings, and they stay on. Once the new `Gemfile.lock` reaches `master`, expect Dependabot PRs against it.

## Deployment

The live site is served from the S3 bucket `www.cbchristensen.net` (`ap-southeast-2`) over HTTP. `www.cbchristensen.net` is the canonical host. A separate nginx host redirects every path on `cbchristensen.net` to the same path on `www.`, and that redirect has to keep working.

Semaphore CI used to build and deploy the site. The last deploy happened on 2022-04-19, before Semaphore's platform overhaul broke the setup. The user holds the AWS credentials. Don't attempt a deploy.

CI goes back to Semaphore after the rebuild, with GitHub Actions as the fallback if Semaphore isn't viable. TODO: document the deploy process once the CI plan is written.

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
