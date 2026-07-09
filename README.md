# Daily Newsfeed

A static website that publishes a fresh list of notable news items every day —
each item shows the headline, a link to the source article, and a one-paragraph
summary, grouped by category. An index page links back through every previous day.

The site is generated automatically by the personal task loop: each morning the
news scan runs, and `generate.ps1` turns that day's items into a new page and
rebuilds the index.

## Layout

- `generate.ps1` — builds one `docs/YYYY-MM-DD.html` page from a news-scan JSON
  file and regenerates `docs/index.html`.
- `docs/` — the published static site (served by GitHub Pages from `/docs`).

## Usage

```pwsh
pwsh -NoProfile -File generate.ps1 -DataFile <news-scan.json> [-Date YYYY-MM-DD]
```

`-DataFile` is the JSON emitted by the loop's `news-scan` toolbelt tool
(fields: `generatedAt`, `newCount`, `categories{<name>:[{title,link,source,summary}]}`).
If `-Date` is omitted it is derived from `generatedAt`.

## Hosting

Designed for **GitHub Pages** served from the `/docs` folder on the default
branch (`.nojekyll` disables Jekyll processing). No build step or dependencies —
plain HTML/CSS.
