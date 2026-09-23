# Writing samples

Three samples, each written to show a different part of the work. They are not three
versions of the same document.

| # | Sample | Doc type (Diátaxis) | What it demonstrates |
| --- | --- | --- | --- |
| 01 | [A staging-to-typed SQL Server pipeline that cannot silently corrupt your data](staging-to-typed-pipeline.md) | How-to guide | Data-engineering depth: staging design, type conversion, reconciliation, referential integrity |
| 02 | *Planned* — API reference for a single endpoint | Reference | Precision and completeness: parameters, verified examples, error behaviour |
| 03 | *Planned* — Explaining word embeddings without the maths | Explanation | Making an abstract concept usable for a non-specialist reader |

## Why these three

Each one targets a different reader need, and together they cover the range a data or
developer-tooling team actually asks for: task completion, exact lookup, and conceptual
understanding. Producing one of these is a writing exercise. Producing all three, and
knowing which one a given request needs, is the job.

## Sample 01 in context

Sample 01 is drawn from a completed project: a five-year UK road-safety pipeline
covering 503,475 collisions, 640,522 casualties, and 920,692 vehicles, loaded into a
validated SQL Server model and reported in Power BI. The guide documents the part of
that pipeline that generalises to any domain — the staging-to-typed pattern and the
reconciliation discipline around it.

The domain-specific results live with the project itself. Here the goal is different:
a reader with their own CSV files should be able to follow the guide and end up with a
pipeline whose failures are loud instead of silent.