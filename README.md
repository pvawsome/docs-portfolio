# Technical writing samples

Documentation I wrote from hands-on engineering work. **The Markdown in `docs/` is the
deliverable** — read it directly on GitHub, no site build required.

> This repository is intentionally separate from my analytics work. It shares no code, no
> configuration, and no CI with any other repository.

## Start here

| Read | What it is |
| --- | --- |
| [`docs/index.md`](docs/index.md) | Landing page — positioning and proof points |
| [`docs/samples/staging-to-typed-pipeline.md`](docs/samples/staging-to-typed-pipeline.md) | **Sample 01** — how-to guide: a staging-to-typed SQL Server pipeline with reconciliation |
| [`docs/about.md`](docs/about.md) | How this portfolio is built, and why each sample declares a Diátaxis doc type |
| [`docs/samples/index.md`](docs/samples/index.md) | Sample index and rationale |
| [`PLAN.md`](PLAN.md) | Build record — what was produced, in what order, and why |

## Sample 01

A how-to guide for landing raw CSVs into SQL Server through a text-only staging layer and
a strongly typed analytical layer, with reconciliation between them so that a successful
load can never be a logically wrong load.

Covers: staging design, positional `BULK INSERT` hazards, `TRY_CONVERT` and counting the
`NULL`s it produces, control-total reconciliation, key uniqueness and orphan checks,
trusted vs. untrusted foreign keys, and reporting views with a declared grain.

Grounded in a completed project: **503,475 collisions, 640,522 casualties, and 920,692
vehicle records** across five years of public UK road-safety data.

## Repository layout

```
.
├── README.md                                    <- you are here
├── PLAN.md                                      <- build record
├── docs/
│   ├── index.md                                 <- landing page
│   ├── about.md                                 <- how the portfolio is built
│   └── samples/
│       ├── index.md                             <- sample index
│       └── staging-to-typed-pipeline.md         <- SAMPLE 01
├── mkdocs.yml                                   <- optional local preview config
└── requirements.txt                             <- optional local preview deps
```

## Optional: local preview

The documents are plain Markdown and render on GitHub as-is. `mkdocs.yml` is included only
so the same files can be previewed as a themed site locally — nothing here is published to
GitHub Pages.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve      # http://127.0.0.1:8000
```

## Conventions

- **Markdown only**, so every change is reviewable in a diff and the docs survive without
  any build tooling.
- **Each sample declares its doc type** (tutorial / how-to / reference / explanation) in a
  callout at the top, because the type sets what a reader is entitled to expect.
- **Callouts use GitHub-native syntax** (`> [!NOTE]`, `> [!TIP]`, `> [!WARNING]`,
  `> [!CAUTION]`) so they render correctly wherever the files are read.
- **Code is real.** Snippets come from executed work. Where something has not been
  verified, the page says so rather than implying otherwise.
- **Limits are stated explicitly.** Every sample ends with where the guidance does *not*
  apply.

## Related

My analytics project — a validated SQL Server and Power BI build on the same road-safety
data: [pvawsome/road-accident-dashboard](https://github.com/pvawsome/road-accident-dashboard)

## Licence

Sample content is published for reading and reference. Please don't republish it as your
own portfolio material. Code snippets may be reused freely.

See [`LICENSE`](LICENSE) for the full terms (written content is all rights reserved;
code snippets and configuration are free to reuse).
