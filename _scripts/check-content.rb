# frozen_string_literal: true

# Checks Bruin's pages for Markdown that kramdown, which builds the site,
# renders differently from GitHub's preview, and for files with Windows line
# endings or the wrong encoding. It also looks for two pages with one
# address, Markdown in an .html page, files that aren't Markdown in a posts
# or course folder, a heading left empty above the notes, look-alike
# characters and accents typed apart from their letters, headings that skip
# a level, spaces in addresses and file names, links that read only "here",
# course notes on the wrong layout, and an updated: before the date. CI runs
# it before the build, and an error stops the deploy.
#
# Usage, from the repo root:
#   bundle exec ruby _scripts/check-content.rb              the site
#   bundle exec ruby _scripts/check-content.rb --root DIR   another copy, such as refs/old-site
#   bundle exec ruby _scripts/check-content.rb --self-test  the checks themselves
#
# Prints path:line: message for each error and path:line: warning: message
# for each warning, with paths relative to the root. Exits 1 if there are
# errors, 0 otherwise. When GITHUB_ACTIONS is true it also prints each
# finding as an annotation, which GitHub shows beside the line.
#
# There's no way to skip a page (decided 2026-10-20). A false alarm needs a
# fix here, with a line in the clean fixture so it stays fixed.
#
# Why our own script and not mdl (agreed 2026-10-20):
# - No new gem. It needs only Ruby's standard library and kramdown, which
#   Jekyll already brings.
# - It reads kramdown's options from _config.yml and parses the way the
#   build does, so it sees what the site will show. The underscore check
#   reads kramdown's output, because a pattern on the source can't tell an
#   opening _ from a closing one.
# - It checks the mistakes this content actually had, which mdl has no rules
#   for, and its messages point Bruin at the README guide.
#
# Costs to watch:
# - We maintain it. A finding blocks the deploy and no page can be skipped,
#   so a false alarm holds the deploy until this script is fixed.
# - It knows only the problems we've taught it. A new kind of mistake needs
#   a new check.
# - The underscore check walks kramdown's parse tree, so a major kramdown
#   upgrade could break it. Run --self-test after any gem update.
# - --self-test and its fixtures are the only tests. Add a fixture with
#   every new check.
#
# If these costs grow, look at mdl again: gem dependency mdl --remote.

require "date"
require "kramdown"
require "optparse"
require "psych"
require "set"
require "time"
require "uri"

# Every finding --self-test expects from _scripts/check-content-fixtures,
# sorted as text, so line 10 of a file comes before line 5. Update it in the
# same commit as any change to a check, a message or a fixture.
SELF_TEST_EXPECTED = <<~'TEXT'.lines(chomp: true)
  _example/2026-01-02-no-permalink.md:1: course notes need their own full address in a permalink: line, like /courses/descartes/a-short-title/ (see "Where files go" in README.md)
  _example/2026-01-03-placeholder-permalink.md:4: course notes need their own full address in a permalink: line, like /courses/descartes/a-short-title/ (see "Where files go" in README.md)
  _example/2026-01-04-permalink-no-slash.md:4: course notes need their own full address in a permalink: line, like /courses/descartes/a-short-title/ (see "Where files go" in README.md)
  _example/2026-01-05-course-address.md:4: course notes need their own full address in a permalink: line, like /courses/descartes/a-short-title/ (see "Where files go" in README.md)
  _example/2026-01-06-other-course.md:4: course notes need their own full address in a permalink: line, like /courses/descartes/a-short-title/ (see "Where files go" in README.md)
  _example/2026-01-08-space in name.md:1: the file name has a space. Use hyphens in place of spaces (see "Where files go" in README.md)
  _example/2026-01-09-layout-post.md:2: course notes need the line layout: course-document in the block at the top (see "Where files go" in README.md)
  _example/2026-01-10-no-layout.md:1: course notes need the line layout: course-document in the block at the top (see "Where files go" in README.md)
  _example/README:1: only Markdown pages go in this folder. Put Word files and other drafts in papers/_posts/_drafts/ (see "Where files go" in README.md)
  files/pdfs/with space.pdf:1: the file name has a space. Rename it with hyphens in place of spaces, and change any links to it to match (see "Where files go" in README.md)
  index.html:5: this page is HTML, so Markdown links show as typed. Write <a href="address">text</a> (see "Where files go" in README.md)
  index.html:5: this page is HTML, so _ and * show as typed. Write <em>text</em> (see "Where files go" in README.md)
  index.html:6: this page is HTML, so _ and * show as typed. Write <em>text</em> (see "Where files go" in README.md)
  no-top-block.md:1: the page needs a block at the top, between two --- lines (see "The block at the top" in README.md)
  papers/_posts/2026-01-02-heading-no-space.md:6: put a space after the # marks (rule 2 in README.md). If this line isn't a heading, start it with a word instead
  papers/_posts/2026-01-03-quote-after-paragraph.md:6: leave an empty line before this quotation (rule 1 in README.md). If it belongs to the paragraph above, join it to that line
  papers/_posts/2026-01-04-heading-after-paragraph.md:6: leave an empty line before this heading (rule 1 in README.md). If it belongs to the paragraph above, join it to that line
  papers/_posts/2026-01-05-list-after-paragraph.md:6: leave an empty line before this list (rule 1 in README.md). If it belongs to the paragraph above, join it to that line
  papers/_posts/2026-01-06-table-after-paragraph.md:6: leave an empty line before this table (rule 1 in README.md). If it belongs to the paragraph above, join it to that line
  papers/_posts/2026-01-07-table-blank-line.md:9: table rows go on consecutive lines, with no empty line between them (rule 4 in README.md)
  papers/_posts/2026-01-08-table-no-separator.md:6: put a line of dashes under the table's first row (rule 4 in README.md)
  papers/_posts/2026-01-09-link-inside-link.md:5: a link inside a link. Write [text](address) (rule 5 in README.md)
  papers/_posts/2026-01-10-relative-link.md:5: link to How_Descartes_thinks_of_himself.pdf: start the address with / or http
  papers/_posts/2026-01-11-missing-file.md:5: no such file: /files/pdfs/absent.pdf. Upload it first, or check the spelling, capitals included
  papers/_posts/2026-01-12-file-wrong-capitals.md:5: no such file: /files/pdfs/Present.pdf. Upload it first, or check the spelling, capitals included
  papers/_posts/2026-01-13-template.md:5: {{ or {% here would be read as a template instruction
  papers/_posts/2026-01-13-template.md:8: {{ or {% here would be read as a template instruction
  papers/_posts/2026-01-14-image-no-description.md:5: describe the image inside the [ ] of ![ ]( )
  papers/_posts/2026-01-15-underscore.md:10: "Christlich-_Religiöses_": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:14: "is_": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:14: "synchronic_": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:20: "_Leit_frage": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:5: "Selbst_bewußt_seins": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:5: "Selbst_seins_": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-15-underscore.md:7: "Sich-zu-_Sich_-Verhalten": underscores inside a word don't make italics here, so use asterisks (rule 3 in README.md). For an underscore that should show, write \_
  papers/_posts/2026-01-16-kramdown-warning.md:5: kramdown says: Footnote definition for '9' not found on line 5
  papers/_posts/2026-01-17-top-block-not-closed.md:1: the block at the top needs a --- line at its end
  papers/_posts/2026-01-18-top-block-unreadable.md:3: the block at the top can't be read (mapping values are not allowed in this context). Check the quotation marks (see "The block at the top" in README.md)
  papers/_posts/2026-01-19-key-twice.md:5: abstract: appears twice in the block at the top, and the site uses only the last one
  papers/_posts/2026-01-20-lang.md:4: lang: should be de, or left out for English
  papers/_posts/2026-01-28-byte-order-mark.md:1: the file starts with an invisible byte order mark, which stops some pages being built. Ask Pep to remove it.
  papers/_posts/2026-01-29-stray-carriage-return.md:5: warning: a stray carriage return character. Ask Pep to remove it.
  papers/_posts/2026-01-30-crlf.md:1: warning: Windows line endings. The page still shows correctly. Ask Pep to convert the file.
  papers/_posts/2026-01-31-not-utf8.md:1: the file isn't saved as UTF-8, so some characters would show wrongly. Open it in GitHub's editor and commit it again.
  papers/_posts/2026-02-01-shared-permalink-a.md:4: another page has this address: papers/_posts/2026-02-02-shared-permalink-b.md. If you copied this block, delete the permalink: line (see "The block at the top" in README.md)
  papers/_posts/2026-02-02-shared-permalink-b.md:4: another page has this address: papers/_posts/2026-02-01-shared-permalink-a.md. If you copied this block, delete the permalink: line (see "The block at the top" in README.md)
  papers/_posts/2026-02-03-draft.docx:1: only Markdown pages go in this folder. Put Word files and other drafts in papers/_posts/_drafts/ (see "Where files go" in README.md)
  papers/_posts/2026-02-04-notes-heading.md:8: the site writes its own "Notes" heading above the notes. Change this heading to ## Notes, or delete it (rule 6 in README.md)
  papers/_posts/2026-02-06-backtick-fence.md:7: three backticks don't start a code block on this site. Use three tildes, ~~~, on the lines before and after the code
  papers/_posts/2026-02-06-backtick-fence.md:9: three backticks don't start a code block on this site. Use three tildes, ~~~, on the lines before and after the code
  papers/_posts/2026-02-07-combining-mark.md:3: "Müller" has a mark typed apart from its letter (U+0308), which can sit in the wrong place. Type the letter with its mark built in, or copy it from "Special characters" in README.md
  papers/_posts/2026-02-07-combining-mark.md:5: "α̉ρετή" has a mark typed apart from its letter (U+0309), which can sit in the wrong place. Type the word again with the Greek Polytonic keyboard (see "Special characters" in README.md)
  papers/_posts/2026-02-08-lookalikes.md:3: ´ (U+00B4) is an accent on its own. For an apostrophe use ’, and for a prime ′, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:5: &#9001; gives 〈 (U+2329), an old angle bracket that some programs swap for a wide Chinese one. Use ⟨, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:5: &#x232A; gives 〉 (U+232A), an old angle bracket that some programs swap for a wide Chinese one. Use ⟩, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:5: 〈 (U+2329) is an old angle bracket that some programs swap for a wide Chinese one. Use ⟨, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:5: 〉 (U+232A) is an old angle bracket that some programs swap for a wide Chinese one. Use ⟩, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:6: &lang; gives 〉 (U+232A) on this site, an old angle bracket the wrong way round. Use ⟨, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:6: &rang; gives 〈 (U+2329) on this site, an old angle bracket the wrong way round. Use ⟩, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:7: &acute; gives ´ (U+00B4), an accent on its own. For an apostrophe use ’, and for a prime ′, from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:7: ¸ (U+00B8) is a cedilla on its own. For a comma type a comma, and copy ç from "Special characters" in README.md
  papers/_posts/2026-02-08-lookalikes.md:8: ┌ (U+250C) is a character for drawing boxes. For corner quotes use ⌜ and ⌝, from "Special characters" in README.md. For a diagram, put a line of ~~~ above it and another below
  papers/_posts/2026-02-08-lookalikes.md:8: ┐ (U+2510) is a character for drawing boxes. For corner quotes use ⌜ and ⌝, from "Special characters" in README.md. For a diagram, put a line of ~~~ above it and another below
  papers/_posts/2026-02-09-modifier-prime.md:5: warning: ʹ (U+02B9) is a letter used in transliteration, such as for the Russian soft sign. For a prime, as in S′, use ′, from "Special characters" in README.md. If you meant ʹ, leave it
  papers/_posts/2026-02-10-heading-skip.md:13: this #### heading comes under a ## heading, so it skips a level. Make it ### (rule 8 in README.md)
  papers/_posts/2026-02-10-heading-skip.md:7: this ### heading comes under the page's title, so it skips a level. Make it ## (rule 8 in README.md)
  papers/_posts/2026-02-11-space-in-address.md:11: a space in the address /files/images/another photo.jpg. Give the file hyphens in place of spaces, and change the address to match (see "Where files go" in README.md)
  papers/_posts/2026-02-11-space-in-address.md:5: a space in the address /files/pdfs/present copy.pdf. Give the file hyphens in place of spaces, and change the address to match (see "Where files go" in README.md)
  papers/_posts/2026-02-11-space-in-address.md:7: a space in the address /files/images/a photo.jpg. Give the file hyphens in place of spaces, and change the address to match (see "Where files go" in README.md)
  papers/_posts/2026-02-11-space-in-address.md:9: a space in the address /papers/2021/12/03/Intentionality-de-se-and-the-Problem-of Self-Consciousness.html. Write %20 in place of each space
  papers/_posts/2026-02-12-here-link.md:11: link text "here" doesn't say where the link goes. Put the link on words that do, such as a title (rule 9 in README.md)
  papers/_posts/2026-02-12-here-link.md:5: link text "here" doesn't say where the link goes. Put the link on words that do, such as a title (rule 9 in README.md)
  papers/_posts/2026-02-12-here-link.md:7: link text "click here" doesn't say where the link goes. Put the link on words that do, such as a title (rule 9 in README.md)
  papers/_posts/2026-02-12-here-link.md:9: link text "hier" doesn't say where the link goes. Put the link on words that do, such as a title (rule 9 in README.md)
  papers/_posts/2026-02-13-space in name.md:1: the file name has a space. Use hyphens in place of spaces (see "Where files go" in README.md)
  papers/_posts/2026-02-14-updated-before-file-date.md:4: updated: is earlier than the date, so the page would read "14 February 2026 · Updated 10 February 2026". Check updated: and the date in the file name (see "The block at the top" in README.md)
  papers/_posts/2026-02-15-updated-before-date.md:5: updated: is earlier than the date, so the page would read "14 February 2026 · Updated 13 February 2026". Check updated: and date: (see "The block at the top" in README.md)
  papers/_posts/no-date.md:1: the file name must start with a date, like 2026-10-20-short-title.md, or the site skips it (see "Where files go" in README.md)
TEXT

FIXTURES = File.join(__dir__, "check-content-fixtures")

MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze

# Jekyll 4 adds these to every site's exclude: list.
JEKYLL_EXCLUDES = %w[.sass-cache .jekyll-cache gemfiles Gemfile Gemfile.lock node_modules
                     vendor/bundle/ vendor/cache/ vendor/gems/ vendor/ruby/].freeze

YAML_CLASSES = [Date, Time, Symbol].freeze

# A line that starts a block, so the line after it isn't a paragraph line.
BLOCK_START = /\A(?:#|>|\||[*+-]\s|\d+\.\s)/
# The markers GitHub's preview shows as a block even straight after a
# paragraph line, where kramdown shows them as text. A numbered list can only
# break into a paragraph there if it starts at 1, so a wrapped line starting
# "1984. " reads as text in both and isn't a finding.
PREVIEW_BLOCK = /\A(?:\#{1,6}(?:\s|\z)|>|\||[*+-]\s+\S|1[.)]\s)/
# The line of dashes under a table's first row.
TABLE_SEPARATOR = /\A\|?[ \t:|+-]*-[ \t:|+-]*\z/
# A line GitHub's preview reads as the first or last line of code between
# backticks. kramdown's own syntax fences code only with ~~~, and reads
# backticks as code inside a paragraph, which an empty line ends.
BACKTICK_FENCE = /\A {0,3}`{3,}[^`]*\z/

# A name Jekyll reads as a post, whatever its extension: its
# Document::DATE_FILENAME_MATCHER, for the file name alone.
POST_NAME = /\A\d{2,4}-\d{1,2}-\d{1,2}-.*\.[^.]+\z/

# What an .html page doesn't show as text: comments, Liquid, scripts, styles
# and tags, which can each run over several lines.
HTML_HIDDEN = %r{<!--.*?-->|\{%-?\s*comment\s*-?%\}.*?\{%-?\s*endcomment\s*-?%\}|\{\{.*?\}\}|\{%.*?%\}|
                 <(script|style)\b.*?</\1\s*>|<[^>]*>}mx
HTML_MARKDOWN_LINK = /\[[^\]]+\]\([^)\s]+\)/
# Italics or bold made with * or _. The text inside has to start with a
# letter, a digit or an opening quotation mark, and can't end with a space,
# so footnote marks such as "(2026)*, (1990)*" and "*.pdf" aren't caught.
HTML_MARKDOWN_EMPHASIS = /(?<![[:alnum:]_*])\*\*?[[:alnum:]“‘„«"'][^*]*(?<!\s)\*\*?(?![[:alnum:]_*])|
                          (?<![[:alnum:]_])__?[[:alnum:]“‘„«"'][^_]*(?<!\s)__?(?![[:alnum:]_])/x

# Inline code on one line, as kramdown reads it. The character checks leave
# code alone, since it shows exactly what was typed.
CODE_SPAN = /(`+)(?!`).+?(?<!`)\1(?!`)/

# Marks that don't add an accent: variation selectors, which choose text or
# emoji style for the character before them, as in the footnote arrow ↩︎,
# and U+20E3, which makes keycap emoji such as 1️⃣.
NOT_AN_ACCENT = /[\u{FE00}-\u{FE0F}\u{E0100}-\u{E01EF}\u{20E3}]/
# A mark on a letter of these scripts, or on a space or symbol, can sit in
# the wrong place, and a ready-made letter or the Greek Polytonic keyboard
# gives the right one. In Hebrew, Arabic, Devanagari and other scripts,
# marks are how vowels are written, so they're left alone.
MARKED_SCRIPTS = /\A[\p{Latin}\p{Greek}\p{Cyrillic}\p{Common}\p{Inherited}]/

# Characters that look right and aren't, raw or as an entity. The named
# entities are the ones kramdown turns into these characters: its table
# swaps &lang; and &rang;, and gives the old brackets for both.
LOOKALIKE = /[\u2329\u232A\u00B4\u00B8\u02B9\u2500-\u257F]|&\#(?:0*(\d+)|[xX]0*(\h+));|&(lang|rang|acute|cedil);/
LOOKALIKE_CODES = Set[0x2329, 0x232A, 0xB4, 0xB8, 0x2B9, *(0x2500..0x257F)].freeze
LOOKALIKE_NAMES = { "lang" => 0x232A, "rang" => 0x2329, "acute" => 0xB4, "cedil" => 0xB8 }.freeze

# Link text that doesn't say where the link goes (rule 9 in README.md).
VAGUE_LINK_TEXT = ["here", "click here", "hier"].freeze

# Words the underscore check leaves out: web and email addresses.
ADDRESS = %r{https?://\S+|\S*@\S+|www\.\S+}
LEFTOVER_UNDERSCORE = /[[:alpha:]]_|_[[:alpha:]]/
# Punctuation around a word, left out when the message names it.
EDGE_PUNCTUATION = /\A[[:punct:]&&[^_]]+|[[:punct:]&&[^_]]+\z/

Finding = Struct.new(:path, :line, :message, :warning) do
  def to_s
    "#{path}:#{line}: #{'warning: ' if warning}#{message}"
  end

  def annotation
    level = warning ? "warning" : "error"
    "::#{level} file=#{annotation_escape(path, property: true)},line=#{line}::#{annotation_escape(message)}"
  end

  # GitHub reads %, carriage returns and newlines as codes in a message, and
  # also : and , in a property such as the file name.
  def annotation_escape(text, property: false)
    text = text.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
    property ? text.gsub(":", "%3A").gsub(",", "%2C") : text
  end
end

# A file to check: its path from the root, and whether Jekyll reads it as a
# post, a document in a collection or a page at the root.
SiteFile = Struct.new(:path, :kind, :collection) do
  def markdown?
    MARKDOWN_EXTENSIONS.include?(File.extname(path).downcase)
  end

  def html?
    File.extname(path).downcase == ".html"
  end

  # Only Markdown files are read in posts and collections, and Markdown and
  # HTML at the root.
  def read?
    markdown? || (kind == :page && html?)
  end
end

class ConfigError < StandardError; end

# The site's settings from _config.yml, and the files Jekyll would read.
class Site
  attr_reader :root, :kramdown_options

  def initialize(root)
    @root = root
    config_path = File.join(root, "_config.yml")
    begin
      @config = Psych.safe_load_file(config_path, permitted_classes: YAML_CLASSES, aliases: true) || {}
    rescue SystemCallError, Psych::Exception => e
      raise ConfigError, "can't read #{config_path}: #{e.message}"
    end
    raise ConfigError, "#{config_path} doesn't hold settings" unless @config.is_a?(Hash)

    markdown = @config.fetch("markdown", "kramdown").to_s
    unless markdown.casecmp?("kramdown")
      raise ConfigError, "_config.yml sets markdown: #{markdown}. These checks assume kramdown."
    end

    # The old site left input unset, and Jekyll 2 then used kramdown's own.
    @kramdown_options = (@config["kramdown"] || {}).transform_keys(&:to_sym)
    @kramdown_options[:input] ||= "kramdown"
    unless @kramdown_options[:input] == "kramdown"
      raise ConfigError, "_config.yml sets kramdown's input to #{@kramdown_options[:input]}. " \
                         "These checks assume kramdown's own syntax."
    end

    @exclude = Array(@config["exclude"]).map(&:to_s) + JEKYLL_EXCLUDES

    # Jekyll sets TZ from timezone:, so a time in a top block reads the same
    # here as in the build.
    ENV["TZ"] = @config["timezone"].to_s if @config["timezone"]
  end

  # Posts in every _posts folder, the documents in each collection and the
  # pages at the root, found the way Jekyll finds them.
  def content_files
    posts = post_folders.flat_map { |dir| files_in(dir).map { |f| SiteFile.new(f, :post) } }
    documents = collections.flat_map do |name|
      files_in("_#{name}").map { |f| SiteFile.new(f, :collection, name) }
    end
    pages = Dir.children(root).sort.filter_map do |name|
      next unless (MARKDOWN_EXTENSIONS + [".html"]).include?(File.extname(name).downcase)
      next if !File.file?(full(name)) || skipped?(name, name)

      SiteFile.new(name, :page)
    end
    (posts + documents + pages).uniq(&:path)
  end

  # Exact names, since macOS ignores case and S3 doesn't.
  def file?(path)
    files.include?(path)
  end

  # Every file under files/, its path from the root.
  def files
    @files ||= Dir.glob("files/**/*", base: root).select { |f| File.file?(full(f)) }.to_set
  end

  def full(path)
    File.join(root, path)
  end

  private

  def collections
    list = @config["collections"]
    names = list.is_a?(Hash) ? list.keys : Array(list)
    names.map(&:to_s) - ["posts"]
  end

  # _posts at the root and in every folder Jekyll reads.
  def post_folders(dir = nil)
    found = []
    posts = dir ? File.join(dir, "_posts") : "_posts"
    found << posts if File.directory?(full(posts))
    Dir.children(dir ? full(dir) : root).sort.each do |name|
      path = dir ? File.join(dir, name) : name
      next if !File.directory?(full(path)) || skipped?(name, path)

      found.concat(post_folders(path))
    end
    found
  end

  # The files in a folder and its subfolders, leaving out _drafts/ and the
  # rest of what Jekyll skips.
  def files_in(dir)
    Dir.glob("**/*", base: full(dir)).sort.filter_map do |entry|
      path = File.join(dir, entry)
      path unless File.directory?(full(path)) || skipped?(entry, path)
    end
  end

  # Like Jekyll's EntryFilter: names starting with . _ # or ending with ~,
  # and anything matching exclude:. The entry is the name relative to the
  # folder being read, the path relative to the root.
  def skipped?(entry, path)
    return true if [entry, File.basename(entry)].any? { |name| name.match?(/\A[._#~]/) }
    return true if entry.end_with?("~")

    directory = File.directory?(full(path))
    @exclude.any? do |pattern|
      File.fnmatch?(pattern, path) || path.start_with?(pattern) || (directory && pattern == "#{path}/")
    end
  end
end

# Runs every check on one file. Each list below names the methods for one
# stage, so a new check is a method and its name in the right list.
class FileCheck
  # For a file in a posts or course folder that isn't Markdown. These go by
  # the name alone and never read the file.
  UNREAD_CHECKS = %i[not_markdown].freeze
  # After the block at the top is read.
  FILE_CHECKS = %i[duplicate_keys lang course_permalink course_layout post_date file_name_space
                   updated_before_date].freeze
  # Each body line of a Markdown file outside ~~~ code blocks. They get the
  # line's number in the file, the line and the line before it.
  LINE_CHECKS = %i[heading_space block_after_paragraph table_rows table_separator
                   links missing_files image_description backtick_fence].freeze
  # Each body line of a Markdown file, code blocks included, since Jekyll
  # runs templates before Markdown.
  LINE_CHECKS_INCLUDING_CODE = %i[template].freeze
  # Each body line of an .html page.
  HTML_LINE_CHECKS = %i[markdown_in_html].freeze
  # After kramdown has parsed a Markdown body.
  TREE_CHECKS = %i[underscores kramdown_warnings notes_heading heading_levels address_spaces
                   vague_links].freeze
  # Each line of the file, the block at the top included, leaving out code:
  # ~~~ blocks, and `…` on one line in a Markdown body. They get the line's
  # number and its text.
  CHARACTER_CHECKS = %i[combining_marks lookalikes].freeze

  attr_reader :file, :data, :key_lines, :findings

  def initialize(site, file)
    @site = site
    @file = file
    @path = file.path
    @data = {}
    @key_lines = {}
    @code_lines = Set.new
    @findings = []
  end

  def run
    return run_all(UNREAD_CHECKS) unless file.read?
    return unless read_bytes

    read_top_block
    return @findings.clear unless published?

    run_all(FILE_CHECKS)
    return unless @body_start

    if file.markdown?
      parse_body
      each_body_line do |n, line, prev, fenced|
        run_all(fenced ? LINE_CHECKS_INCLUDING_CODE : LINE_CHECKS_INCLUDING_CODE + LINE_CHECKS, n, line, prev)
      end
      run_all(TREE_CHECKS)
    else
      each_body_line { |n, line, prev| run_all(HTML_LINE_CHECKS, n, line, prev) }
    end
    each_text_line { |n, text| run_all(CHARACTER_CHECKS, n, text) }
  end

  # Jekyll leaves out a page whose published: is false or empty.
  def published?
    @data.fetch("published", true) ? true : false
  end

  # The permalink: as written, unless it's missing or holds a placeholder
  # such as :title.
  def literal_permalink
    permalink = value_text(@data["permalink"])
    permalink unless permalink.empty? || permalink.include?(":")
  end

  private

  def add(line, message, warning: false)
    @findings << Finding.new(@path, line, message, warning)
  end

  def run_all(checks, *args)
    checks.each { |check| send(check, *args) }
  end

  # Byte checks. Returns false if the rest can't be read. A byte order mark
  # is an error (decided 2026-10-25): Jekyll then copies a page or course
  # document as it is, block at the top and all, instead of building it.
  # Line endings stay warnings, since Bruin can't change them himself.
  def read_bytes
    bytes = File.binread(@site.full(@path))
    if bytes.start_with?("\xEF\xBB\xBF".b)
      add(1, "the file starts with an invisible byte order mark, which stops some pages being built. " \
             "Ask Pep to remove it.")
      bytes = bytes.byteslice(3..)
    end
    if bytes.include?("\r\n")
      add(1, "Windows line endings. The page still shows correctly. Ask Pep to convert the file.", warning: true)
    end
    if (stray = bytes =~ /\r(?!\n)/n)
      add(bytes.byteslice(0, stray).count("\n") + 1, "a stray carriage return character. Ask Pep to remove it.",
          warning: true)
    end

    text = bytes.force_encoding(Encoding::UTF_8)
    unless text.valid_encoding?
      add(1, "the file isn't saved as UTF-8, so some characters would show wrongly. " \
             "Open it in GitHub's editor and commit it again.")
      return false
    end
    @lines = text.gsub("\r\n", "\n").split("\n", -1)
    true
  end

  # Reads the block at the top the way Jekyll does, which allows spaces after
  # either --- and a closing ... instead. Sets @body_start to the number of
  # lines before the body, or leaves it nil if the body can't be found.
  def read_top_block
    unless @lines.first&.match?(/\A---\s*\z/)
      @body_start = 0
      if file.markdown?
        add(1, 'the page needs a block at the top, between two --- lines (see "The block at the top" in README.md)')
      end
      return
    end

    close = (1...@lines.size).find { |i| @lines[i].match?(/\A(?:---|\.\.\.)\s*\z/) }
    return add(1, "the block at the top needs a --- line at its end") unless close

    @body_start = close + 1
    yaml = @lines[1...close].join("\n")
    begin
      data = Psych.safe_load(yaml, permitted_classes: YAML_CLASSES, aliases: true)
      raise Psych::Exception, "its lines need the form name: value" unless data.nil? || data.is_a?(Hash)
    rescue Psych::Exception => e
      # Psych gives the line where the part it couldn't read starts.
      line = e.respond_to?(:line) ? e.line.to_i + 1 : 1
      problem = e.respond_to?(:problem) && e.problem ? e.problem : e.message
      return add(line, "the block at the top can't be read (#{problem}). " \
                       'Check the quotation marks (see "The block at the top" in README.md)')
    end

    @data = data || {}
    # Psych.parse gives false for an empty block. Key lines count from 0 at
    # the line after the first ---.
    document = Psych.parse(yaml)
    root = document && document.root
    return unless root.is_a?(Psych::Nodes::Mapping)

    root.children.each_slice(2) do |key, _value|
      (@key_lines[key.value] ||= []) << key.start_line + 2 if key.is_a?(Psych::Nodes::Scalar)
    end
  end

  # The line a key is on, or line 1 if the block doesn't have it.
  def key_line(key)
    @key_lines.fetch(key, []).last || 1
  end

  # A YAML value as written. YAML reads :title as a symbol.
  def value_text(value)
    value.is_a?(Symbol) ? ":#{value}" : value.to_s
  end

  # Calls the block with each body line's number in the file, the line, the
  # line before it, and whether it's part of a ~~~ code block, fences
  # included.
  def each_body_line
    prev = ""
    @lines.each_with_index do |line, i|
      next if i < @body_start

      yield i + 1, line, prev, @code_lines.include?(i + 1)
      prev = line
    end
  end

  # Calls the block with each line's number in the file and its text, from
  # the first line on, leaving out ~~~ code blocks. In a Markdown body,
  # inline code becomes a space.
  def each_text_line
    @lines.each_with_index do |line, i|
      next if @code_lines.include?(i + 1)

      yield i + 1, (file.markdown? && i >= @body_start ? line.gsub(CODE_SPAN, " ") : line)
    end
  end

  # The first line from n on that holds text, or n.
  def line_with(n, text)
    (n..@lines.size).find { |i| @lines[i - 1].include?(text) } || n
  end

  # kramdown's tree, the body lines where each kind of element starts, and
  # the file's lines inside ~~~ code blocks. Those come from the tree, so a
  # fence counts only where kramdown starts a block: not straight after a
  # paragraph line, and not if it's never closed.
  def parse_body
    @doc = Kramdown::Document.new(@lines[@body_start..].join("\n"), @site.kramdown_options)
    @starts = Hash.new { |hash, type| hash[type] = Set.new }
    each_element do |el, line|
      @starts[el.type] << line if el.options[:location]
      next unless el.type == :codeblock && el.options[:fenced]

      # The opening fence, the code and the closing fence.
      first = line + @body_start
      @code_lines.merge(first..(first + el.value.count("\n") + 1))
    end
  end

  # Calls the block with each element and the body line it starts on.
  # Footnote text sits in its own tree, under each :footnote element. Table
  # cells have no line of their own, so they get their table's.
  def each_element(el = @doc.root, line = 1, &block)
    line = el.options[:location] || line
    yield el, line
    each_element(el.value, line, &block) if el.type == :footnote && el.value.is_a?(Kramdown::Element)
    el.children.each { |child| each_element(child, line, &block) }
  end

  # Whether kramdown starts one of these elements on line n of the file.
  def kramdown_starts?(n, *types)
    types.any? { |type| @starts[type].include?(n - @body_start) }
  end

  # The line before was a paragraph line, as far as GitHub's preview goes.
  def paragraph_line?(line)
    !line.strip.empty? && !line.match?(BLOCK_START) && !line.match?(/\A\s/) && !line.start_with?("[^")
  end

  # Unread checks.

  # Jekyll reads a file in a posts folder as a post if its name starts with a
  # date, so a Word file named like a draft stops the build with a Ruby
  # error. It skips the folder's other files. In a course folder it reads
  # every file, and publishes one without a block at the top at the course's
  # address plus the file's extension, such as /courses/descartes.docx. A
  # file with no extension there stops the build.
  def not_markdown
    return if file.kind == :post && !File.basename(@path).match?(POST_NAME)

    add(1, "only Markdown pages go in this folder. Put Word files and other drafts in papers/_posts/_drafts/ " \
           '(see "Where files go" in README.md)')
  end

  # File checks.

  def duplicate_keys
    @key_lines.each do |key, lines|
      lines.drop(1).each do |line|
        add(line, "#{key}: appears twice in the block at the top, and the site uses only the last one")
      end
    end
  end

  def lang
    return if @data["lang"].nil? || %w[de en-AU].include?(value_text(@data["lang"]))

    add(key_line("lang"), "lang: should be de, or left out for English")
  end

  # Course notes need an address of their own inside the course's. Without
  # one they take the course page's address, /courses/<name>/, and replace
  # it. A placeholder makes Jekyll 4 build the address from the file name,
  # and without the closing / the course page links to an address the
  # server doesn't have.
  def course_permalink
    return unless file.kind == :collection && !course_index?

    course = "/courses/#{file.collection}/"
    permalink = value_text(@data["permalink"])
    return if permalink.start_with?(course) && permalink.end_with?("/") && !permalink.include?(":") &&
              permalink != course

    add(key_line("permalink"), "course notes need their own full address in a permalink: line, like " \
                               '/courses/descartes/a-short-title/ (see "Where files go" in README.md)')
  end

  # The course's own page, index.md in its folder, which has the course's
  # address.
  def course_index?
    File.dirname(@path) == "_#{file.collection}" && File.basename(@path, ".*") == "index"
  end

  # Course notes show no date or version (decided 2026-10-25), which only
  # their own layout leaves out. A paper's block copied into a course folder
  # would bring layout: post with it.
  def course_layout
    return unless file.kind == :collection && !course_index?
    return if value_text(@data["layout"]) == "course-document"

    add(key_line("layout"), "course notes need the line layout: course-document in the block at the top " \
                            '(see "Where files go" in README.md)')
  end

  def post_date
    return unless file.kind == :post && file.markdown?
    return if File.basename(@path).match?(/\A\d{4}-\d{1,2}-\d{1,2}-.+\.(?:md|markdown)\z/i)

    add(1, 'the file name must start with a date, like 2026-10-20-short-title.md, or the site skips it ' \
           '(see "Where files go" in README.md)')
  end

  # In a posts or course folder. The check for files that aren't Markdown
  # covers the other files there, and Jekyll never reads _drafts/.
  def file_name_space
    return unless %i[post collection].include?(file.kind) && @path.match?(/[[:space:]]/)

    add(1, 'the file name has a space. Use hyphens in place of spaces (see "Where files go" in README.md)')
  end

  # Papers and blog posts show both dates, so an updated: before the date
  # reads wrongly. Course notes show neither (decided 2026-10-25), so they
  # aren't checked. Compares the days the page shows.
  def updated_before_date
    return unless file.kind == :post

    updated = shown_day(@data["updated"], own_offset: true)
    date = @data.key?("date") ? shown_day(@data["date"]) : file_name_day
    return unless updated && date && updated < date

    shown = [date, updated].map { |day| day.strftime("%-d %B %Y") }
    source = @data.key?("date") ? "date:" : "the date in the file name"
    add(key_line("updated"), %(updated: is earlier than the date, so the page would read "#{shown[0]} · ) +
                             %(Updated #{shown[1]}". Check updated: and #{source} ) +
                             '(see "The block at the top" in README.md)')
  end

  # The day a date in the top block shows on the page. Jekyll moves date:
  # into the site's time zone, and Liquid shows updated: in the offset it
  # was written with, as Jekyll's build of 2026-10-25 did. Nil for anything
  # that isn't a date.
  def shown_day(value, own_offset: false)
    return value if value.instance_of?(Date)

    time = value if value.is_a?(Time)
    time ||= Time.parse(value) if value.is_a?(String) && value.match?(/\A\d{4}-\d{1,2}-\d{1,2}/)
    time && (own_offset ? time : time.localtime).to_date
  rescue ArgumentError
    nil
  end

  # The date at the start of a post's file name, which Jekyll uses when the
  # block has no date:.
  def file_name_day
    day = File.basename(@path)[/\A(\d{4}-\d{1,2}-\d{1,2})-/, 1]
    day && Date.strptime(day, "%Y-%m-%d")
  rescue ArgumentError
    nil
  end

  # Line checks. Each finding about kramdown's blocks is checked against its
  # tree, so a line is reported only where the site really shows it
  # differently from the preview.

  # kramdown reads ##Notes as a heading, GitHub's preview as text.
  def heading_space(n, line, _prev)
    return unless line.match?(/\A#+[^#\s]/) && kramdown_starts?(n, :header)

    add(n, "put a space after the # marks (rule 2 in README.md). " \
           "If this line isn't a heading, start it with a word instead")
  end

  # The preview starts a block here, kramdown carries on the paragraph.
  def block_after_paragraph(n, line, prev)
    return unless line.match?(PREVIEW_BLOCK) && paragraph_line?(prev)

    kind, types = { "#" => ["heading", [:header]], ">" => ["quotation", [:blockquote]],
                    "|" => ["table", [:table]] }.fetch(line[0], ["list", %i[ul ol]])
    # The preview shows a table only with a line of dashes under its first row.
    return if kind == "table" && !@lines[n].to_s.match?(TABLE_SEPARATOR)
    return if kramdown_starts?(n, *types)

    add(n, "leave an empty line before this #{kind} (rule 1 in README.md). " \
           "If it belongs to the paragraph above, join it to that line")
  end

  # A row after an empty line, below another row. A row with dashes under it
  # starts a table of its own.
  def table_rows(n, line, prev)
    return unless line.start_with?("|") && prev.strip.empty?
    return unless n - 3 >= @body_start && @lines[n - 3].start_with?("|")
    return if @lines[n].to_s.match?(TABLE_SEPARATOR) || !kramdown_starts?(n, :table)

    add(n, "table rows go on consecutive lines, with no empty line between them (rule 4 in README.md)")
  end

  def table_separator(n, line, prev)
    following = @lines[n].to_s
    return unless line.start_with?("|") && !prev.start_with?("|") && following.start_with?("|")
    return if following.match?(TABLE_SEPARATOR) || !kramdown_starts?(n, :table)

    add(n + 1, "put a line of dashes under the table's first row (rule 4 in README.md)")
  end

  def links(n, line, _prev)
    if line.match?(/\]\(\s*\[/)
      add(n, "a link inside a link. Write [text](address) (rule 5 in README.md)")
      return
    end
    # Skips footnote references, as in "[^1](S.517-518)", a note number
    # followed by a page reference in brackets.
    line.scan(/\[([^\]]*)\]\(([^)\s]+)\)/).each do |text, target|
      next if text.start_with?("^") || target.match?(%r{\A(?:/|#|https?://|mailto:)})

      add(n, "link to #{target}: start the address with / or http")
    end
  end

  def missing_files(n, line, _prev)
    line.scan(%r{\]\((/files/[^)\s]+)\)}).flatten.each do |target|
      path = begin
        URI.decode_www_form_component(target.sub(/[?#].*/, "").delete_prefix("/"))
      rescue ArgumentError
        nil
      end
      next if path && @site.file?(path)

      add(n, "no such file: #{target}. Upload it first, or check the spelling, capitals included")
    end
  end

  def image_description(n, line, _prev)
    add(n, "describe the image inside the [ ] of ![ ]( )") if line.match?(/!\[\s*\]\(/)
  end

  # The preview shows code between two lines of backticks. The site reads
  # them as code inside a paragraph, which the first empty line ends, and
  # shows what follows as text. Each of the two lines is reported, since
  # both need changing.
  def backtick_fence(n, line, _prev)
    return unless line.match?(BACKTICK_FENCE)

    add(n, "three backticks don't start a code block on this site. " \
           "Use three tildes, ~~~, on the lines before and after the code")
  end

  def template(n, line, _prev)
    add(n, "{{ or {% here would be read as a template instruction") if line.match?(/\{\{|\{%/)
  end

  # HTML line checks.

  # Jekyll doesn't run Markdown in an .html page, so a Markdown link or
  # italics there show as typed, as Bruin's thesis link once did.
  def markdown_in_html(n, _line, _prev)
    text = html_text[n - 1 - @body_start]
    if text.match?(HTML_MARKDOWN_LINK)
      add(n, 'this page is HTML, so Markdown links show as typed. Write <a href="address">text</a> ' \
             '(see "Where files go" in README.md)')
    end
    return unless text.match?(HTML_MARKDOWN_EMPHASIS)

    add(n, 'this page is HTML, so _ and * show as typed. Write <em>text</em> (see "Where files go" in README.md)')
  end

  # The body's lines with what the page doesn't show as text turned into
  # spaces, so a comment or tag over several lines keeps the line numbers.
  def html_text
    @html_text ||= @lines[@body_start..].join("\n")
                                        .gsub(HTML_HIDDEN) { |hidden| hidden.gsub(/[^\n]/, " ") }
                                        .split("\n", -1)
  end

  # Tree checks.

  # An underscore left next to a letter in the rendered text is emphasis that
  # didn't happen: "Sich-zu-_Sich_", "Selbst_seins_", "is_ synchronic_".
  # Leaves out addresses, and any word typed with \_ on purpose. kramdown
  # turns \_ into a plain _, so only the source shows which it was.
  def underscores
    each_element do |el, line|
      next unless el.type == :text && el.value.match?(LEFTOVER_UNDERSCORE)

      el.value.to_enum(:scan, /\S+/).map { Regexp.last_match }.each do |match|
        word = match[0].gsub(ADDRESS, "").gsub(EDGE_PUNCTUATION, "")
        next unless word.match?(LEFTOVER_UNDERSCORE)

        escaped = word.gsub("_", "\\_")
        n = source_line(line + el.value[0, match.begin(0)].count("\n") + @body_start, word, escaped)
        next if @lines[n - 1].to_s.include?(escaped)

        add(n, %("#{word}": underscores inside a word don't make italics here, ) +
               "so use asterisks (rule 3 in README.md). For an underscore that should show, write \\_")
      end
    end
  end

  # The first line from n on that holds the word, as typed or escaped. Text
  # in a table cell only knows the table's first line.
  def source_line(n, word, escaped)
    (n..@lines.size).find { |i| @lines[i - 1].include?(word) || @lines[i - 1].include?(escaped) } || n
  end

  # kramdown's own warnings, apart from the "No link definition" ones that
  # Bruin's bracketed insertions in quotations cause. kramdown counts lines
  # from the start of the body, so its numbers are moved to the file's.
  def kramdown_warnings
    @doc.warnings.each do |warning|
      next if warning.start_with?("No link definition for link ID")

      line = warning[/line (\d+)/, 1]
      add(line ? line.to_i + @body_start : 1,
          "kramdown says: #{warning.gsub(/line (\d+)/) { "line #{Regexp.last_match(1).to_i + @body_start}" }}")
    end
  end

  # kramdown moves the notes to the end of the page, and
  # _includes/content.html swaps a "## Notes" or "### Notes" heading there
  # for its own. Any other heading last on the page would stand empty above
  # the site's. Goes by kramdown's tree, not by the line above the first
  # note, since a note can be written anywhere and still shows at the end.
  def notes_heading
    return if @starts[:footnote].empty?

    last = last_block
    return unless last&.type == :header && !replaced_notes_heading?(last)

    add(last.options[:location] + @body_start, 'the site writes its own "Notes" heading above the notes. ' \
                                               "Change this heading to ## Notes, or delete it (rule 6 in README.md)")
  end

  def last_block
    @doc.root.children.reverse.find { |el| el.type != :blank }
  end

  # A "## Notes" or "### Notes" heading, which _includes/content.html
  # removes from a page with notes, wherever it is.
  def replaced_notes_heading?(el)
    !@starts[:footnote].empty? && [2, 3].include?(el.options[:level]) && el.options[:raw_text] == "Notes" &&
      el.attr.all? { |name, value| name == "id" && value == "notes" }
  end

  # A heading more than one level below the one before (rule 8 in
  # README.md), starting from the page's title at level 1. Only the page's
  # own headings count, not those inside a quotation, a list or a note. The
  # heading above the notes is left out: the site replaces it with its own
  # level 2 "Notes", or the notes heading check reports it.
  def heading_levels
    notes = last_block unless @starts[:footnote].empty?
    previous = 1
    above = "the page's title"
    @doc.root.children.each do |el|
      next unless el.type == :header && !el.equal?(notes) && !replaced_notes_heading?(el)

      level = el.options[:level]
      if level > previous + 1
        add(el.options[:location] + @body_start,
            "this #{'#' * level} heading comes under #{above}, so it skips a level. " \
            "Make it #{'#' * (previous + 1)} (rule 8 in README.md)")
      end
      previous = level
      above = "a #{'#' * level} heading"
    end
  end

  # The address of a link or image, written in Markdown or HTML.
  def link_address(el)
    case el.type
    when :a then el.attr["href"]
    when :img then el.attr["src"]
    when :html_element then el.attr[{ "a" => "href", "img" => "src" }[el.value]]
    end
  end

  # GitHub's preview doesn't read an address with a space as a link, and
  # the site's own files have hyphens in place of spaces (decided
  # 2026-10-25). A space kramdown drops, as in "]( https://…)", isn't in its
  # tree, and neither is one written as %20.
  def address_spaces
    each_element do |el, line|
      target = link_address(el)
      next unless target&.match?(/[[:space:]]/)

      advice = if target.start_with?("/files/")
                 "Give the file hyphens in place of spaces, and change the address to match " \
                 '(see "Where files go" in README.md)'
               else
                 "Write %20 in place of each space"
               end
      add(line_with(line + @body_start, target), "a space in the address #{target}. #{advice}")
    end
  end

  # A link that reads only "here" (rule 9 in README.md), its text taken from
  # inside any italics or bold.
  def vague_links
    each_element do |el, line|
      next unless el.type == :a || (el.type == :html_element && el.value == "a")

      text = link_text(el).gsub(/[[:space:]]+/, " ").gsub(/\A[[:punct:] ]+|[[:punct:] ]+\z/, "")
      next unless VAGUE_LINK_TEXT.include?(text.downcase)

      add(line + @body_start, %(link text "#{text}" doesn't say where the link goes. ) +
                              "Put the link on words that do, such as a title (rule 9 in README.md)")
    end
  end

  def link_text(el)
    return el.value if %i[text codespan].include?(el.type)

    el.children.map { |child| link_text(child) }.join
  end

  # Character checks.

  # An accent or breathing typed as a mark of its own after its letter, as
  # in "α̉ρετή" (U+0309). One finding for each word on a line.
  def combining_marks(n, text)
    # Splitting into letters is slow, and most lines have no mark at all.
    return unless text.match?(/\p{M}/)

    words = text.split.select { |word| word.scan(/\X/).any? { |cluster| loose_mark?(cluster) } }
    words.map { |word| word.gsub(/\A[[:punct:]]+|[[:punct:]]+\z/, "") }.uniq.each do |word|
      codes = word.scan(/\X/).select { |cluster| loose_mark?(cluster) }
                  .flat_map { |cluster| cluster.scan(/\p{M}/).grep_v(NOT_AN_ACCENT) }
                  .uniq.map { |mark| code_point(mark.ord) }
      fix = if word.match?(/\p{Greek}/)
              'Type the word again with the Greek Polytonic keyboard (see "Special characters" in README.md)'
            else
              'Type the letter with its mark built in, or copy it from "Special characters" in README.md'
            end
      add(n, %("#{word}" has a mark typed apart from its letter (#{codes.join(', ')}), ) +
             "which can sit in the wrong place. #{fix}")
    end
  end

  # A grapheme cluster holding an accent typed apart from its letter.
  def loose_mark?(cluster)
    cluster.gsub(NOT_AN_ACCENT, "").match?(/\p{M}/) && cluster.match?(MARKED_SCRIPTS)
  end

  def code_point(code)
    format("U+%04X", code)
  end

  # One finding for each look-alike on a line, for each way it's typed.
  def lookalikes(n, text)
    found = {}
    text.scan(LOOKALIKE) do
      match = Regexp.last_match
      code = lookalike_code(match)
      found[match[0].downcase] ||= [match[0], code] if code
    end
    found.each_value do |typed, code|
      what, fix = lookalike_advice(typed, code)
      char = "#{code.chr(Encoding::UTF_8)} (#{code_point(code)})"
      named = " on this site" if %w[&lang; &rang;].include?(typed)
      message = typed.start_with?("&") ? "#{typed} gives #{char}#{named}, #{what}" : "#{char} is #{what}"
      add(n, "#{message}. #{fix}", warning: code == 0x2B9)
    end
  end

  # The character a match stands for, if it's a look-alike. In an .html
  # page the browser reads &lang; and &rang; as the right brackets.
  def lookalike_code(match)
    code = if match[1] then match[1].to_i
           elsif match[2] then match[2].hex
           elsif match[3] then LOOKALIKE_NAMES[match[3]] if file.markdown? || !%w[lang rang].include?(match[3])
           else match[0].ord
           end
    code if LOOKALIKE_CODES.include?(code)
  end

  # What the character is, and what to use instead.
  def lookalike_advice(typed, code)
    guide = 'from "Special characters" in README.md'
    case code
    when 0x2329, 0x232A
      right = { "&lang;" => "⟨", "&rang;" => "⟩" }.fetch(typed, code == 0x2329 ? "⟨" : "⟩")
      what = if %w[&lang; &rang;].include?(typed)
               "an old angle bracket the wrong way round"
             else
               "an old angle bracket that some programs swap for a wide Chinese one"
             end
      [what, "Use #{right}, #{guide}"]
    when 0xB4 then ["an accent on its own", "For an apostrophe use ’, and for a prime ′, #{guide}"]
    when 0xB8 then ["a cedilla on its own", "For a comma type a comma, and copy ç #{guide}"]
    when 0x2B9
      ["a letter used in transliteration, such as for the Russian soft sign",
       "For a prime, as in S′, use ′, #{guide}. If you meant ʹ, leave it"]
    else
      ["a character for drawing boxes",
       "For corner quotes use ⌜ and ⌝, #{guide}. For a diagram, put a line of ~~~ above it and another below"]
    end
  end
end

# Every finding for the site at root, in file and line order.
def check_site(root)
  site = Site.new(root)
  checks = site.content_files.map { |file| FileCheck.new(site, file).tap(&:run) }
  # Checks that compare files with each other go here, using each
  # FileCheck's file, data, key_lines, published? and literal_permalink,
  # and checks on files the linter doesn't read.
  findings = (checks.flat_map(&:findings) + shared_permalinks(checks) + file_spaces(site)).uniq(&:to_s)
  findings.each_with_index.sort_by { |finding, i| [finding.path, finding.line, i] }.map(&:first)
end

# Pages with the same permalink:, one of which silently replaces the other.
# Each names the others. Placeholders are left to the course check, since
# the old site's 32 course documents all had /courses/:collection/:title/.
def shared_permalinks(checks)
  groups = checks.select(&:published?).group_by(&:literal_permalink).except(nil)
  groups.each_value.select { |group| group.size > 1 }.flat_map do |group|
    group.flat_map do |check|
      line = check.key_lines.fetch("permalink", [1]).last
      (group - [check]).map do |other|
        Finding.new(check.file.path, line, "another page has this address: #{other.file.path}. " \
                                           "If you copied this block, delete the permalink: line " \
                                           '(see "The block at the top" in README.md)', false)
      end
    end
  end
end

# A PDF, picture or slides whose name has a space, which a link has to
# write as %20. The site's own files have hyphens instead (decided
# 2026-10-25).
def file_spaces(site)
  site.files.select { |path| path.match?(/[[:space:]]/) }.sort.map do |path|
    Finding.new(path, 1, "the file name has a space. Rename it with hyphens in place of spaces, and change " \
                         'any links to it to match (see "Where files go" in README.md)', false)
  end
end

def self_test
  actual = check_site(FIXTURES).map(&:to_s).sort
  expected = SELF_TEST_EXPECTED.sort
  missing = expected - actual
  unexpected = actual - expected
  missing.each { |line| puts "missing: #{line}" }
  unexpected.each { |line| puts "unexpected: #{line}" }
  return false unless missing.empty? && unexpected.empty?

  puts "self-test passed: #{actual.size} findings as expected"
  true
end

def plural(count, word)
  "#{count} #{word}#{'s' unless count == 1}"
end

def main(argv)
  root = "."
  test = false
  OptionParser.new do |opts|
    opts.banner = "Usage: bundle exec ruby _scripts/check-content.rb [--root DIR] [--self-test]"
    opts.on("--root DIR", "Check the site in DIR (default: the current folder)") { |dir| root = dir }
    opts.on("--self-test", "Run the checks on the fixtures and compare with SELF_TEST_EXPECTED") { test = true }
  end.parse!(argv)
  raise OptionParser::NeedlessArgument, argv.first unless argv.empty?
  return self_test if test

  findings = check_site(root)
  annotate = ENV["GITHUB_ACTIONS"] == "true"
  findings.each do |finding|
    puts finding
    puts finding.annotation if annotate
  end
  errors = findings.count { |finding| !finding.warning }
  unless findings.empty?
    $stdout.flush
    warn "#{plural(errors, 'error')} and #{plural(findings.size - errors, 'warning')} " \
         "in #{plural(findings.map(&:path).uniq.size, 'file')}"
  end
  errors.zero?
rescue ConfigError, OptionParser::ParseError => e
  warn "check-content: #{e.message}"
  false
end

exit(main(ARGV)) if $PROGRAM_NAME == __FILE__
