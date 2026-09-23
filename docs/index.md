# Data and AI documentation, written by someone who runs the pipeline

I write developer-facing documentation from hands-on engineering work — not from
secondhand research. My background is data analytics: Python, pandas, SQL Server,
Power BI, Neo4j. Every snippet on this site has been executed against real data
before it was written down.

That distinction matters more than it used to. When a language model can draft a
plausible-looking tutorial in seconds, the scarce thing is not prose — it is
**verification**. A code sample that has never been run is a liability, not
documentation. I write what I have actually built, and I say so when I have not.

## What I write

- **How-to guides and quickstarts** for data tooling — SQL Server, Python data
  pipelines, BI models — where the reader must be able to *finish the task*.
- **Concept and explanation docs** that make a technical idea land for a reader who
  does not yet have the vocabulary.
- **API and reference material** structured so a developer can find the answer
  without reading the whole page.
- **Data engineering runbooks and internal SOPs** — operational procedures where a
  wrong step has consequences.

## Proof before claim

The pipeline behind my main sample processed **503,475 collisions, 640,522 casualties,
and 920,692 vehicles** across five years of public UK road-safety data. Every stage had
a control total, and every control total was reconciled:

| Check | Result |
| --- | --- |
| Staging rows vs. typed-table rows (3 tables) | Matched exactly |
| Unique keys vs. total rows (3 entities) | Matched — zero missing |
| Child records orphaned from a parent | Zero |
| Foreign keys accepted as trusted by SQL Server | 3 of 3 |

The documentation describes that pipeline. It also documents the two things that
actually went wrong along the way, because that is where the useful writing lives.

## Samples

<div class="grid cards" markdown>

- **01 · A staging-to-typed SQL Server pipeline that cannot silently corrupt your data**

  A how-to guide: land raw CSVs as text, convert with `TRY_CONVERT`, and reconcile
  every stage so a successful load can never be a logically wrong load.

  [Read the guide →](samples/staging-to-typed-pipeline.md)

- **02 · Coming soon — an API reference page**

  A single endpoint documented end to end: authentication, parameters, verified
  request/response examples, and error behaviour.

- **03 · Coming soon — a concept explainer**

  Turning word embeddings into something a non-specialist can actually reason about.

</div>

## How to read this site

Each sample declares its **Diátaxis** doc type — tutorial, how-to guide, reference, or
explanation — because the type determines what a reader is entitled to expect from it.
If you want to know why that matters, and how the rest of this site is structured,
[read how this portfolio is built](about.md).

## Working together

I take on scoped documentation work alongside my main work in data analytics —
single deliverables with a fixed price and a defined outcome, which is the easiest way
to find out whether my writing fits your product.

**Start with one page.** Send me a doc that is missing, wrong, or that your users keep
asking about. I will write that one page and you can judge the work before committing
to anything larger.