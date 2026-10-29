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
├── index.html         Bruin's introduction. Its layout, home, adds the latest blog post and three recent papers
├── about.md, impressum.md  The about page and the Impressum
├── papers/_posts/     The papers, each named <date>-<slug>.md
│   └── _drafts/       Bruin's Word files and Markdown drafts. Jekyll never builds the folder, but anyone can read it on GitHub
├── blog/_posts/       The blog posts
├── _descartes/, _technology/, _dilthey/  The three courses, one collection each: the course documents and the course's index.md
├── files/             Images, PDFs and a PowerPoint, in images/, pdfs/ and ppts/, published at the same paths
├── feed.xml           The RSS feed, hand-written Liquid
├── README.md          The repo's front page on GitHub, with Bruin's "Writing in Markdown" guide. Excluded from the build
├── .claude/skills/    Project skills, see Skills below
├── .gitattributes     LF line endings for text files committed from a clone; refs/ and the content check's fixtures keep their bytes
├── .github/workflows/check.yml  The GitHub check and its notices to the user, see Content checks below
├── plans/             Plan sets, one folder each (only AGENTS.md and CLAUDE.md are committed)
│   ├── done/          Finished plan sets
│   └── tools/         screenshots/ takes Playwright screenshots of the site in every colour mode, favicon/ writes the icon files, fonts/ downloads the fonts and writes _sass/site/_fonts.scss. Each has a README.md
└── refs/old-site/     The old Jekyll 2 site, a read-only reference, deleted before the merge to master
```

The site is built at the repo root. Bruin's content sits at the paths it had in the old site, so `git log` on a file shows its whole history and Bruin finds his files where they always were. Keep it there.

## Jekyll

The site runs Jekyll 4.4.1, the newest stable release as of 2026-10-18. The old site ran Jekyll 2.5.3. See `plans/done/install-latest-jekyll/install-latest-jekyll-00-overview.md` for the install.

- **Never change a published URL.** Every page, paper, course document and file keeps its exact live path. `_scripts/live-url-inventory.tsv` lists all of them, and `_scripts/check-urls.rb` checks every build against it. Jekyll 4 builds course and some paper URLs differently from Jekyll 2, so those pages pin theirs with a literal `permalink:`, see below. The one exception so far: on 2026-10-25 two image files got hyphens in place of the spaces in their names, agreed by the user with Bruin, so their old addresses are gone. No page's URL changed.
- Keep `refs/` and `plans/` in the `exclude:` list in `_config.yml`. Otherwise Jekyll builds the old site's pages over the new ones. Jekyll 4 adds its own defaults (`Gemfile`, `Gemfile.lock`, `vendor/bundle/` and so on), so don't repeat them.
- `url` is the canonical host, `http://www.cbchristensen.net`. `jekyll doctor` warns and exits with status 1 without it.
- `timezone: UTC` matches the 2022 build, so every front matter date lands on the same day in its URL.
- `permalink: date` is Jekyll 4's default. Writing it down protects the paper URLs if a future Jekyll changes the default.
- Don't remove `timezone` or `permalink` without re-running the URL parity check in the rebuild overview.
- `kramdown.input: kramdown` is kramdown's own syntax, which the site has always used. Don't switch to GFM, Jekyll 4's default. It changes the heading ids on 35 pages, breaking any outside link to a section, and renders some of Bruin's Markdown differently. `README.md`'s "Writing in Markdown" guide has the rules Bruin follows.
- Each course document holds its live URL as a literal `permalink:`, and so do the two papers whose URLs keep a curly apostrophe or a space. Never edit those lines. Bruin can retitle a page without moving it. A new course document needs a literal `permalink:` of its own too, such as `/courses/descartes/a-short-title/`. Without one it builds to `/courses/<collection>/` and replaces the course's index page. A placeholder such as `:title` makes Jekyll 4 take the URL from the file name. The content check rejects both, and any `permalink:` two pages share.
- `strict_front_matter: true` makes a top block YAML can't read fail the build. Without it, Jekyll publishes the page anyway, at a URL with the build day's date. Keep it.
- `future: true` publishes a paper dated after the build's day in UTC. Bruin works in Canberra, 10 or 11 hours ahead, so a paper he dates today and commits in the morning is in the future for a UTC build. Without the setting, Jekyll would leave it out and still exit `0`. The user wants to revisit it before the new site goes live (asked on 2026-10-21). If it goes, the content check should warn about a date after today in UTC. The rebuild overview's CI section has the note.
- Six papers carry `lang: de`, the ones written entirely in German. A new paper written in German needs it too.
- `feed.xml` is hand-written, with no feed plugin. It builds every URL with `absolute_url`, which encodes the space and the curly apostrophes in the two pinned papers' URLs.

## Theme

The theme is Minima 2.5.2, Jekyll's default theme, copied into the repo from its `v2.5.2` tag at commit `c6e74bb` and reshaped for Bruin's writing. There's no theme gem and no plugin. Its Sass is ported from `@import` to `@use`, and `_sass/minima/LICENSE.txt` carries its MIT licence.

Styles:

- Colours come only from custom properties in `_sass/site/_tokens.scss`, with light, dark, more-contrast and print palettes. The one exception is the system colours (`Canvas`, `CanvasText`, `Highlight`, `LinkText`) in the forced-colours rules. Sizes are in `rem`, so they follow the root size and the reader's own default font size.
- A Sass deprecation warning means something needs porting. Don't silence it with `silence_deprecations` or `quiet_deps`, and don't make it fatal with `fatal_deprecations`. A fatal warning would turn a Dependabot bump of `sass-embedded` into a failed check.
- Source maps are off (`sass: sourcemap: never`), so none get deployed. To debug the styles, set it to `always` locally and back to `never` before committing.
- The fonts are self-hosted variable WOFF2 files under the SIL Open Font License, with the licences in `assets/fonts/`. Literata sets the text, and Source Sans 3 the headings, metadata and navigation. Literata replaced the old site's Merriweather, which has no Greek, because six papers quote polytonic Greek. Don't subset or rename the files, and don't load fonts from Google, Bunny Fonts or any other CDN.
- `plans/tools/fonts/` downloads the font files and writes `_sass/site/_fonts.scss`. Each `unicode-range` has to match its file, or the browser skips a file it needs with no error, so re-run the tool rather than editing a range by hand.

Markup:

- `_includes/content.html` rewrites kramdown's footnote and table markup by exact string match. It deletes Bruin's own "Notes" heading above the footnotes, in the rendered page only, and puts the theme's in its place. It also names the footnote links for screen readers ("Note 2", "Back to reference 2") and numbers the table boxes. After a kramdown update, check that the style guide still shows one "Notes" heading above the footnotes. `README.md` has the rest of that check.
- Interface text on German pages carries `lang="en-AU"`, written by `_includes/interface-lang.html`, so screen readers read it in English (WCAG 3.1.2). Any new label, heading or date the theme writes gets the include in its opening tag, as in `<footer class="site-footer"{% include interface-lang.html %}>`. Bruin's text never does.
- Navigation links live in `_data/navigation.yml`. The header shows them at every width, stacked one per line on phones. There's no menu button, by the user's choice.
- Papers show `version` (free text, printed as written) and `updated` (a date) under the date, on screen and in print. Course documents use `_layouts/course-document.html`, a copy of `post.html` that shows no date, "Updated" or version, because Bruin keeps those in the files for himself (decided 2026-10-25). Keep the two layouts in step.
- `/courses/` lists the collections by their `order` key in `_config.yml`, because Jekyll sorts `site.collections` by label. A new course needs an `order`, or it sorts first.
- The home page shows the latest blog post's first paragraph, cut from the rendered post at its first `</p>` (decided 2026-10-20). Jekyll's `post.excerpt` cuts the source file at its first empty line, and a file with Windows line endings has none, so the excerpt was the whole post. Cutting the HTML gives the same paragraph whatever the line endings. Anything above the first paragraph, such as a heading or a picture, comes along, and a post with no paragraph shows whole. Rule 7 of the guide in `README.md` asks Bruin to start a post with a paragraph.
- The style guide in `style-guide/` is unpublished and builds only with `--unpublished`. It's the test bed for theme changes.

The user chose each of these on purpose. They aren't bugs, so don't undo them:

- The text column is 52rem with 1.8 leading. Print has 1.8 leading too and forces no page breaks. The user chose these on 2026-10-20, in place of the first build's 38rem, 1.5 on screen, 1.4 in print and a new page for each `h2`.
- Print keeps the wide outer margins, on the edge away from the binding, so students have room for notes. Don't swap them to the inner edge.
- The site title is "Carleton B. Christensen", and the print button inverts its colours on hover. The user chose both on 2026-10-20, in place of the first build's "Bruin Christensen" and a hover that only darkened the text and border. The footer's "Carleton Bruin Christensen" is meant to stay.
- `html` has `scrollbar-gutter: stable` (2026-10-25), so the centred column doesn't shift sideways between short and long pages. On short pages that leaves a strip of page background at the right end of the header and footer, where a scrollbar would sit.
- Footnote jump targets keep their focus outline after a mouse click. Safari draws it then and Chrome and Firefox don't, a difference the user accepted on 2026-10-26.
- In Safari, a page scroll by trackpad or mouse wheel with the pointer over a table box leaves the arrow keys unable to scroll that box. It's a Safari bug, not the theme's, and keyboard-only use isn't affected. The user chose on 2026-10-27, and again on 2026-10-29, to leave it rather than add a script.

## Quick commands

Run from the repo root.

- `rbenv install`: installs the Ruby named in `.ruby-version`. Use it on a new machine.

- `bundle install`: installs the gems in `Gemfile.lock`.
- `bundle exec jekyll build`: builds the site into `_site/`.
- `bundle exec jekyll build --unpublished --destination "$(mktemp -d)"`: builds the site with the style guide, without touching `_site/`.
- `bundle exec jekyll doctor`: checks the config and content for problems. It should print "Everything looks fine."
- `bundle exec ruby _scripts/check-content.rb`: the content check, over Bruin's pages. It should print nothing.
- `bundle exec ruby _scripts/check-content.rb --self-test`: runs the content check on its fixtures and compares the findings with the ones it expects.
- `ruby _scripts/check-urls.rb _scripts/live-url-inventory.tsv "$out"`: after a build into `$out`, checks that every live URL is still in it. It should print `missing: 0`.

`bundle exec jekyll serve` is the user's to run. Don't start it. While it runs, agents run doctor as `bundle exec jekyll doctor --config _config.yml,"$nocache"`, where `$nocache` is a file outside the repo holding `disable_disk_cache: true`: a plain `jekyll doctor` empties `.jekyll-cache/`, which `jekyll serve` uses, and doctor has no flag to stop it.

For visual checks, ask the user to look at their running server. They run it as `jekyll serve --unpublished`, so the style guide shows.

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

The theme added no gems. It's a copy in the repo, and the Sass compiler comes with Jekyll through `jekyll-sass-converter`.

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
6. **Keep Bruin's words**. Content changes fix markup, never his text, unless he agrees through the user. The user decides small fixes, such as a stray full stop, under a standing agreement with Bruin. Markup fixes need the user's agreement too, and go in a commit of their own, as the ones in `782b899` did.

## Updating this file

**IMPORTANT**: When making changes that affect the repository structure, dependencies, or workflows, update this AGENTS.md file and any subdirectory AGENTS.md files specific to those changes. This ensures future LLM sessions have accurate context.
