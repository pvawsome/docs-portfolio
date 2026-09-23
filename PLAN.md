# BUILD PLAN — docs-portfolio (sample 01)

## Hard constraint
DO NOT touch `pvawsome/road-accident-dashboard`. The portfolio goes in a NEW repo
`docs-portfolio`. Nothing in this build reads from or writes to that repo.

## Deliverable
A publishable MkDocs + Material site containing sample 01: a how-to guide on
designing a staging-to-typed SQL Server pipeline that cannot silently corrupt data.
Grounded in the real, completed UK road-safety pipeline (503,475 / 640,522 / 920,692 rows).

## Steps
- [x] Recon: GitHub identity = pvawsome; source material mined from the interview guide
- [x] Skeleton: mkdocs.yml, .gitignore, requirements.txt, README.md
- [x] Site pages: docs/index.md, docs/about.md, docs/samples/index.md
- [x] Sample 01 page (3 chunks: staging, typing/reconciliation, keys/views/limits)
- [x] publish.sh written (build + git init + repo create + gh-deploy)
- [ ] Local git init + first commit           <- user runs publish.sh
- [ ] mkdocs build verification               <- user runs publish.sh
- [ ] Create repo + push + enable Pages       <- user runs publish.sh

## Blocked on user
Terminal approvals are not reachable from this client. User must either:
  (a) update the Hermes app so approval prompts reach them, or
  (b) run the final build/push commands themselves (exact commands supplied).

## Content rules for sample 01
- Every SQL snippet is T-SQL and matches the proven project pattern.
- No invented numbers: row counts and findings are the real project's.
- State doc type (Diátaxis how-to) explicitly — demonstrates framework fluency.
- Include the failure modes actually encountered (positional BULK INSERT mismatch,
  service-account file permissions). Real troubleshooting is what buyers pay for.