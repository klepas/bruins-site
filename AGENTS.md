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
├── _data/navigation.yml  The header and footer links, in order
├── _includes/         head, header and footer, from Minima 2.5.2; content.html, which fixes kramdown's footnote and table markup; interface-lang.html, which marks interface text lang="en-AU" on German pages; print-button.html
├── _layouts/          base, page and post, from Minima 2.5.2; post serves papers and blog posts; course-document is a copy of post for course documents, without the date, "Updated" and version line, which Bruin keeps in the files for himself, so keep the two in step; home lists the latest blog post and three recent papers; course-overview is each course's index, with the hero and its document list
├── _sass/minima/      Minima's Sass as @use modules, with its MIT licence in LICENSE.txt
├── _sass/site/        The site's own Sass: _tokens.scss holds every colour as a custom property, in light, dark and two more-contrast palettes plus a print palette as its last block, _fonts.scss the @font-face rules, _content.scss the footnote, table and other Markdown styles, _post.scss the article header, print button and abstract box, _listings.scss the shared .item-list used by the home page and every index, _home.scss the introduction, _course.scss the course hero, _print.scss the print stylesheet, loaded last
├── _scripts/          The two checks, see Content checks below: check-content.rb, the content check, with its self-test fixtures in check-content-fixtures/; check-urls.rb, the URL check; live-url-inventory.tsv, every URL the live site served, which the URL check reads
├── assets/css/main.scss  Compiles to assets/css/main.css, with no source map
├── assets/js/skip-links.js  The site's only script, after GOV.UK Frontend: focuses the target of "Skip to content" and "Back to top", so VoiceOver follows. The links work without it
├── assets/fonts/      Literata and Source Sans 3 as variable WOFF2 files, with their OFL licences
├── favicon.svg, favicon.ico, apple-touch-icon.png  The site icon, "CBC" in Literata, gold on the header blue. plans/tools/favicon/ writes all three, so change them there, not by hand
├── papers.html, blog.html, courses.html  The /papers/, /blog/ and /courses/ indexes. /courses/ sorts the collections on their order key
├── style-guide/       Theme test pages, published: false, built with --unpublished
├── papers/, blog/, _dilthey/, about.md, index.html, files/  Bruin's content, being restored from refs/old-site/ by the content plan set. Don't delete it
├── .claude/skills/    Project skills, see Skills below
├── .gitattributes     LF line endings for text files committed from a clone; refs/ and the content check's fixtures keep their bytes
├── .github/workflows/check.yml  The GitHub check and its notices to the user, see Content checks below
├── plans/             Plan sets, one folder each (only AGENTS.md and CLAUDE.md are committed)
│   ├── done/          Finished plan sets
│   └── tools/         screenshots/ takes Playwright screenshots of the site in every colour mode, favicon/ writes the icon files. Each has a README.md
└── refs/old-site/     The old Jekyll 2 site, a read-only reference, deleted before the merge to master
```

The new site gets built at the repo root. Content goes back to the paths it had in the old site: `papers/_posts/`, `blog/_posts/`, the `_descartes/`, `_dilthey/` and `_technology/` collections, `files/`, and the top-level pages. Update this section as files land.

## Jekyll

The site runs Jekyll 4.4.1, the newest stable release as of 2026-10-18. The old site ran Jekyll 2.5.3. See `plans/done/install-latest-jekyll/install-latest-jekyll-00-overview.md` for the install.

- **Never change a published URL.** Every page, paper, course document and file keeps its exact live path. `_scripts/live-url-inventory.tsv` lists all of them, and `_scripts/check-urls.rb` checks every build against it. Jekyll 4 builds course and some paper URLs differently from Jekyll 2, and the overview plan explains how to pin them. The one exception so far: on 2026-10-25 two image files got hyphens in place of the spaces in their names, agreed by the user with Bruin, so their old addresses are gone. No page's URL changed.
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
- `bundle exec ruby _scripts/check-content.rb`: the content check, over Bruin's pages. It should print nothing.
- `bundle exec ruby _scripts/check-content.rb --self-test`: runs the content check on its fixtures and compares the findings with the ones it expects.
- `ruby _scripts/check-urls.rb _scripts/live-url-inventory.tsv "$out"`: after a build into `$out`, checks that every live URL is still in it. It should print `missing: 0`.

`bundle exec jekyll serve` is the user's to run. Don't start it. While it runs, agents run doctor as `bundle exec jekyll doctor --config _config.yml,"$nocache"`, where `$nocache` is a file outside the repo holding `disable_disk_cache: true`: a plain `jekyll doctor` empties `.jekyll-cache/`, which `jekyll serve` uses, and doctor has no flag to stop it.

To check visual changes, or to share screenshots with Bruin, use `plans/tools/screenshots/`. Its `README.md` covers setup and running.

## Skills

On-demand references.

Invoke the one whose topic matches the task. Each skill is the single owner of its subject, and the AGENTS.md files carry only pointers to it.

| Skill | Use when |
| --- | --- |
| `antislop` | Writing or editing prose: Markdown docs (README, AGENTS.md) and in-code comments/docstrings. Suppresses AI writing tells; enforces plain English and punctuation rules. |

## Linting and formatting

The content check, `_scripts/check-content.rb`, is the repo's only linter, and nothing formats the code. See Content checks below.

## Content checks

`_scripts/check-content.rb` catches what GitHub's preview hides from Bruin: Markdown that kramdown, which builds the site, renders differently, and other mistakes in his pages and files that would show wrongly or break the site. Its header comment and the "Writing in Markdown" guide in `README.md` list what it checks. Every check has a fixture in `_scripts/check-content-fixtures/` and a line in `SELF_TEST_EXPECTED`, so the self-test fails if a check stops finding its problem or finds one in the clean fixtures.

- `.github/workflows/check.yml` runs the content check, its self-test, a production build, the URL check and `jekyll doctor` on every push and pull request. An error fails the check. Once deploys exist, a failed check blocks the deploy (decided 2026-10-20).
- The same workflow tells the user about problems on `master`, where Bruin edits, since GitHub emails only the person who pushed (decided 2026-10-25). A failed check opens an issue assigned to `NOTIFY_LOGIN`, the user's GitHub account, or comments on the one already open, and the next passing push closes it. Each file with warnings gets one issue, closed once the file has none. These jobs read the content check's `path:line: warning: message` lines, and rely on it printing its findings only after it has read every file. If either changes, change the "Pass the content warnings on" step to match.
- `_scripts/check-urls.rb` checks the build against `_scripts/live-url-inventory.tsv`, every URL the live site served on 2026-10-18. A missing URL means a page moved: fix the cause, never the list. Remove a row only when the user agrees a page is gone for good (decided 2026-10-21).
- Some checks only warn, Windows line endings among them (decided 2026-10-20). A warning leaves the exit status at `0`, and on `master` it opens a notice issue for the file. The script's header comment says which checks warn.
- There's no way to skip a page. A false alarm means fixing the content check, not silencing it.
- Run the self-test after any change to the script or its fixtures, and after any gem update.
- `strict_front_matter: true` in `_config.yml` makes a broken top block fail the build. Keep it.
- `.gitattributes` must keep `refs/** -text` and the fixtures line last. The later line wins, and without them git would convert the CRLF files in `refs/old-site/` and the fixtures.

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

CI goes back to Semaphore after the rebuild, with GitHub Actions as the fallback if Semaphore isn't viable. The checks already run in GitHub Actions, whichever service deploys, see Content checks. TODO: document the deploy process once the CI plan is written.

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
