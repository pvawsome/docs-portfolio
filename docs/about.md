# How this portfolio is built

This site is not a folder of exported Word files. It is a small docs-as-code project,
because that is how documentation actually ships inside engineering teams.

## The stack

| Layer | What is used here | Why it matters to a client |
| --- | --- | --- |
| Source format | Markdown with YAML front matter and admonitions | Reviewable in a pull request, diffable, portable |
| Site generator | MkDocs with the Material theme | Standard docs-as-code pipeline; builds from a CI job |
| Version control | Git, one commit per logical change | Every edit is traceable; changes can be reviewed |
| Publishing | GitHub Pages, built from `main` | No hosting to manage, no build server to babysit |

If your team already uses MkDocs, Docusaurus, Sphinx, or a bespoke pipeline, the
authoring skills transfer directly — the tooling is a weekend to learn, and it is not
what you are hiring for.

## Every sample declares its doc type

The samples here follow the **Diátaxis** framework, which separates documentation into
four types with genuinely different jobs:

| Type | Orientation | Answers | In this portfolio |
| --- | --- | --- | --- |
| **Tutorial** | Learning | "Teach me by walking me through it" | — |
| **How-to guide** | Task | "How do I accomplish X?" | Sample 01 |
| **Reference** | Information | "What exactly are the parameters?" | Sample 02 (planned) |
| **Explanation** | Understanding | "Why does this work this way?" | Sample 03 (planned) |

The framework earns its place because the failure mode it prevents is common and
expensive: a page that tries to teach, instruct, and reference at the same time, and
succeeds at none of them. Labelling the type up front tells the reader what they are
allowed to expect, and tells me when to stop writing.

## What is deliberately absent

- **No filler tutorials.** Nothing here was written to reach a word count.
- **No unverified code.** Where a snippet has not been executed, that is stated on the
  page rather than implied by context.
- **No claim without a check.** Numbers on this site come from reconciliation queries
  that were actually run, not from memory or estimation.

## A note on AI

I use AI tooling in my writing process, the same way I use it in analysis — for
drafting alternatives, for compression, and for catching inconsistencies. It is not
the source of the technical content. The pipeline design, the failure modes, and the
verification steps come from work I did, and the accuracy of every statement remains
my responsibility. When the thing being documented has to be *correct*, an editor's
judgement is still the product.