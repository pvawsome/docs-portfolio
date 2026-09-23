# Build record — docs-portfolio

A record of what was produced, in what order, and why. Kept in the repo so the reasoning
survives alongside the documents.

## What this repository is

A set of technical writing samples. The Markdown in `docs/` is the deliverable — it is
read directly on GitHub. There is no published website; the documents are the artifact.

## Constraint observed throughout

The analytics repository `pvawsome/road-accident-dashboard` must never be modified by
anything here. This repository is fully separate: its own git history, its own branches,
no shared configuration or CI. The dashboard's `pushedAt` was verified unchanged
(2026-08-31) before and after every operation in this build.

## Source material

Sample 01 is grounded in a completed analytics project. The technical detail was taken
from the project's own interview and architecture guide rather than reconstructed from
memory, so every claim in the guide traces to work that was actually done:

- UK road-safety open data, 2020-2024
- 503,475 collisions / 640,522 casualties / 920,692 vehicles
- Python + pandas preparation, SQL Server staging and typed layers, Power BI reporting

## What was produced

| Step | Output |
| --- | --- |
| Recon | GitHub identity confirmed (`pvawsome`); dashboard repo identified and excluded |
| Skeleton | `mkdocs.yml`, `.gitignore`, `requirements.txt` |
| Site pages | `docs/index.md`, `docs/about.md`, `docs/samples/index.md` |
| Sample 01 | `docs/samples/staging-to-typed-pipeline.md` — 8-step how-to guide |
| Publish | Pushed to `pvawsome/docs-portfolio`; brief GitHub Pages deploy |
| Final shape | Pages removed; docs converted to GitHub-native callouts; publish script deleted |

## Why the shape changed

The repository was first published as a GitHub Pages site. It was then reworked so the
Markdown is the primary reading surface, because:

1. **Durability.** Markdown with no build step cannot break. No dependency upgrade, no
   theme change, no CI job can make the documents unreadable.
2. **Reviewability.** Every change is a diff on a text file.
3. **Portability.** The same files render on GitHub, in an editor, in a pull request, and
   in any static site generator later if one is ever wanted.

The conversion replaced Material-for-MkDocs admonition syntax (`!!! note`) with
GitHub-native callouts (`> [!NOTE]`), which render correctly wherever the files are read.

## Sample 01 content notes

- Every SQL snippet is T-SQL and matches the proven pattern from the real project.
- Row counts and reconciliation results are the project's actual figures.
- The doc type (Diátaxis: how-to guide) is declared at the top of the page.
- Two real failure modes are documented: the positional `BULK INSERT` column-order
  mismatch, and the SQL Server service-account file-permission problem.
- The guide ends by stating where the pattern does not apply, including that row counts
  are not exposure-adjusted risk rates.

## Status

Complete for sample 01. Samples 02 (API reference) and 03 (concept explainer) are scoped
in `docs/samples/index.md` and not yet written.
