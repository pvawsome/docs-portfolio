# docs-portfolio

Technical writing samples — data pipelines, SQL, and AI systems documented from
hands-on engineering work. Built as a docs-as-code project and published with
GitHub Pages.

**Live site:** https://pvawsome.github.io/docs-portfolio/

> This repository is intentionally separate from my analytics work. It shares no code,
> no configuration, and no CI with any other repository.

## What's here

| Path | Contents |
| --- | --- |
| `docs/index.md` | Landing page — positioning and proof points |
| `docs/about.md` | How the portfolio is built, and why each sample declares a Diátaxis doc type |
| `docs/samples/index.md` | Sample index and rationale |
| `docs/samples/staging-to-typed-pipeline.md` | **Sample 01** — how-to guide: a staging-to-typed SQL Server pipeline with reconciliation |
| `mkdocs.yml` | MkDocs + Material configuration and navigation |

## Sample 01

A how-to guide for landing raw CSVs into SQL Server through a text-only staging layer
and a strongly typed analytical layer, with reconciliation between them so that a
successful load can never be a logically wrong load.

Covers: staging design, positional `BULK INSERT` hazards, `TRY_CONVERT` and counting the
`NULL`s it produces, control-total reconciliation, key uniqueness and orphan checks,
trusted vs. untrusted foreign keys, and reporting views with a declared grain.

Grounded in a completed project: 503,475 collisions, 640,522 casualties, and 920,692
vehicle records across five years of public UK road-safety data.

## Running locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

mkdocs serve      # local preview at http://127.0.0.1:8000
mkdocs build      # static output into site/
```

## Publishing

The site builds from `main` and deploys to GitHub Pages. Any change to `docs/` or
`mkdocs.yml` is a normal pull-request-shaped edit — which is the point of building
documentation this way.

## Conventions

- **Markdown only**, no proprietary formats, so every change is reviewable in a diff.
- **Each sample declares its doc type** (tutorial / how-to / reference / explanation) in
  a callout at the top, because the type sets what a reader is entitled to expect.
- **Code is real.** Snippets are taken from executed work. Where something has not been
  verified, the page says so rather than implying otherwise.
- **Limits are stated explicitly.** Every sample ends with where the guidance does *not*
  apply.

## Licence

Sample content is published for reading and reference. Please don't republish it as your
own portfolio material. Code snippets may be reused freely.