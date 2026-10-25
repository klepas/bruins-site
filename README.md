[![Build Status](https://semaphoreci.com/api/v1/klepas/bruins-site/branches/master/badge.svg)](https://semaphoreci.com/klepas/bruins-site)

# cbchristensen.net source

These are the source files that are managed by the Ruby static site generator [Jekyll](http://github.com/mojombo/jekyll) to build [cbchristensen.net](http://cbchristensen.net/).

## Writing in Markdown

The site turns each Markdown file into a web page with a program called kramdown. GitHub's Preview tab follows slightly different rules, so a page can look right there and wrong on the site. The rules below keep the two the same, and a few help readers who use a screen reader.

### Where files go

| What | Folder | File name |
| --- | --- | --- |
| A paper | `papers/_posts/` | `2026-10-20-short-title.md` |
| A blog post | `blog/_posts/` | `2026-10-20-short-title.md` |
| Course notes | `_descartes/`, `_technology/` or `_dilthey/` | Like the others in the folder |
| A PDF, image or slides | `files/pdfs/`, `files/images/` or `files/ppts/` | Hyphens in place of spaces, such as `frequent-network-2031.jpg` |
| Word files and other drafts | `papers/_posts/_drafts/` | Anything. The site never shows this folder, but anyone can see it on GitHub |

A paper's web address comes from its date and its file name. Once a paper is online, don't rename the file or change its `date:`, or links to the old address stop working. The same goes for a PDF or picture, whose address is its file name. To mark a revision, change `version:` or add `updated:`.

To start a new paper or post, open its folder on GitHub, choose **Add file**, then **Create new file**, and paste your text in. That keeps the file in the form the site expects. Uploading from your computer is for PDFs, images and slides only. Upload one before you link to it, and start the link's address with `/files/`, as in `[the title](/files/pdfs/name.pdf)`.

New course notes need their own address in a `permalink:` line, ending in `/`, such as `permalink: /courses/descartes/a-short-title/`. No other page may have the same address. Keep the line `layout: course-document` from the notes you copied: course notes don't show their date or version on the site, but those lines stay in the file for your own records.

The introduction on the home page lives in `index.html`. It's written in HTML, not Markdown, so a link there is `<a href="/files/pdfs/name.pdf">the title</a>` and italics are `<em>…</em>`. Markdown there shows up on the page as brackets and underscores.

### The block at the top

Every page starts with a block between two `---` lines. Copy it from an existing paper and change the values:

```yaml
---
layout: post
title: "The title, with *italics* if needed"
date: 2026-10-20
version: "20.10.2026"
author: Carleton B. Christensen
abstract: "A sentence or two. It shows above the paper, and on the home page while the paper is one of the three newest."
---
```

- On papers, `version:` and `updated:` (a date, written like `date:`) show under the title. On course notes the site shows no date or version, so they're for your own records.
- Add the line `lang: de` to a paper written in German.
- A `permalink:` line holds a page's address. Leave it exactly as it is. If the block you copied has one, delete it from the new page, or the new page takes the old one's place on the site.
- Keep the title and the abstract inside straight double quotes, `"…"`. For quotation marks inside them, use curly ones: “ ” and ‘ ’.
- If the abstract starts `abstract: >`, as in the newer papers, leave out the quotes and indent each line below it by two spaces.
- Write each line once. With two `abstract:` lines, the site shows only the second.

### Rules the preview won't warn you about

1. Leave an empty line before a heading, a quotation, a list or a table. Without one, the site shows the `#`, `>`, `*` or `|` as plain text at the end of the paragraph above.
2. Put a space after the `#` marks of a heading: `## Notes`, not `##Notes`.
3. For italics inside a word, use asterisks: `Sich-zu-*Sich*-Verhalten`. Underscores, as in `_Sein und Zeit_`, only work at the start of a word.
4. Put table rows on consecutive lines, with a line of dashes under the first row:

   ```
   | Mode    | 2006 | 2011 |
   |---|---|---|
   | walking | 5%   | 6%   |
   ```

5. A link is `[text](address)`. Pasting from a word processor sometimes gives `[text]([address](address))`, a link inside a link, which goes nowhere.
6. For a footnote, write `[^1]` in the text and `[^1]: The note.` on its own line at the end. The site puts the notes under a "Notes" heading of its own. If you put a heading above the notes, make it `## Notes`, which the site replaces. Any other heading there would show as well.
7. Start a blog post with an ordinary paragraph. The home page shows the first paragraph of the latest post.
8. Choose a heading's number of `#` by its place in the outline, not by how big it looks. The page's title is the top level, so main sections are `##`, sections inside them `###`, and so on, one level at a time.
9. Put a link on words that say where it goes, such as a title, not on "here". Screen reader users often hear a page's links as a list, without the words around them.

Square brackets in a quotation, as in “[the senses—C.B.C.]”, are fine as they are.

### Special characters

Some programs, older ones on Windows in particular, put in a character that looks right but isn't, such as an accent mark where an apostrophe belongs. Copy what you need from here instead.

| For | Copy |
| --- | --- |
| Apostrophe and single quotes | ’ ‘ |
| Double quotes | “ ” |
| German quotes | „ “ « » |
| Dashes: a long one, and one for ranges such as 1993–2000 | — – |
| Ellipsis, section and copyright | … § © |
| German letters | ä ö ü Ä Ö Ü ß |
| Other accented letters | à è é ë í ï ó û ç ñ ø ý |
| Latin with a long mark, as in primā | ā ē ū |
| Angle brackets, as in ⟨s, t⟩ | ⟨ ⟩ |
| Corner quotes, as in ⌜t⌝ | ⌜ ⌝ |
| Prime, as in S′ | ′ |
| Logic | Φ → ≠ ∴ ◆ |
| Greek with a smooth breathing | ἀ ἐ ἠ ἰ ὀ ὐ ὠ |
| Greek with a rough breathing | ἁ ἑ ἡ ἱ ὁ ὑ ὡ ῥ |
| Greek with an accent | ά έ ή ί ό ύ ώ |
| Greek elision, as in δ᾽ | ᾽ |
| Greek words already on the site | ἀρετή ἐποχή ἑρμηνεία φρόνησις |

For anything else in Greek, use the Greek Polytonic keyboard, which Macs and Windows both have. It types each letter with its breathing and accent built in. A mark added on its own can sit in the wrong place.

### Pictures

To show a picture, upload it to `files/images/`, then write `![description](/files/images/name.jpg)` where it should go. Readers who can't see the picture have its description read out by their screen reader in its place. So say what the picture shows, not just what it's called, and include any words that are part of it, such as a quotation on a photo. The diagram in Descartes lecture 3 is an example. Its description starts "Hand-drawn diagram. A large circle stands for Descartes’ mind."

### Checking your work

After each commit, GitHub checks the site. It takes about a minute, with a small yellow dot next to the commit until it's done. A green tick then means all is well. A red cross means the check found something that would show wrongly on the site, or that a page which was online has gone missing, for example after a file was renamed.

Click the cross, then **Details**, to see the file, the line and what to change. Then edit the file in the browser and commit again. Pep hears about a red cross too, and can help. If the check itself looks wrong, tell Pep.

## Copyright and licensing

(C) 2004- Carleton Bruin Christensen.
