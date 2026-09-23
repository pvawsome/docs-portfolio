# A staging-to-typed SQL Server pipeline that cannot silently corrupt your data

!!! abstract "Doc type — how-to guide (Diátaxis)"

    This is a **how-to guide**: it assumes you can already write SQL and want to
    accomplish a specific task. It is goal-oriented, not a tutorial, and it will not
    explain what a primary key is. If you want the reasoning behind the pattern
    instead of the steps, that belongs in an explanation doc — see
    [how this portfolio is built](../about.md) for why I keep those separate.

**What you will end up with:** CSV files landing in SQL Server through two layers — a
text-only staging layer and a strongly typed analytical layer — with a reconciliation
step between them, so a load that *succeeds* can never be a load that is *wrong*.

**Time:** about 45 minutes for the first table; the rest is repetition.

**Applies to:** SQL Server 2017 or later. The pattern transfers to PostgreSQL
(`COPY` + typed tables) and Snowflake (`COPY INTO` + `TRY_*` casts), with different
syntax for the load itself.

---

## Why two layers instead of one

The obvious design loads a CSV straight into a table with typed columns. Do that, and
you inherit a specific failure mode: **one malformed value kills the whole load.** A
date written as `2023-13-45`, an empty string in an integer column, a stray `N/A` in a
decimal — the insert aborts, you get an error naming a row, and you learn nothing about
how many other rows were also broken.

The two-layer pattern separates *ingestion* from *interpretation*:

| Layer | Column types | Job |
| --- | --- | --- |
| `stg` (staging) | **All text** | Land the bytes exactly as they arrived, faithfully |
| `dbo` (typed) | Real types, keys, constraints | Enforce what the data is *supposed* to be |

Because staging is text, nothing can fail on type grounds. Because the typed layer
converts with `TRY_CONVERT`, a bad value becomes `NULL` instead of an error — and
`NULL`s can be **counted**, which turns an anonymous crash into a measurable,
queryable number.

!!! tip "The one-sentence version"

    Staging tells you *what arrived*. The typed layer tells you *what is valid*. The
    reconciliation step between them tells you the difference — and the difference is
    the whole point.

---

## Before you start

You need:

- A database where you can create schemas and tables.
- The SQL Server service account able to **read the folder** your CSVs live in. This
  is not automatic and it is the single most common reason a first bulk load fails —
  see [Troubleshooting](#troubleshooting) before you get stuck.
- CSV files with a header row, comma-separated, UTF-8 encoded.

Throughout this guide I use a running example: three related public files describing
road collisions, the vehicles involved, and the casualties. The scale is real —
503,475 collisions, 920,692 vehicle records, 640,522 casualties — but nothing below
depends on the domain. If your files describe orders, claims, or shipments, the steps
are identical.

---

## Step 1 — Create the staging layer with text-only columns

Create a schema for staging, then define each staging table with **every column as text**.
Not `VARCHAR(50)` because you think values are short — text, generously sized, for
everything except the key columns you can bound confidently.

```sql
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO

DROP TABLE IF EXISTS stg.Collisions;
GO

CREATE TABLE stg.Collisions
(
    collision_index      VARCHAR(20)  NULL,
    collision_year       VARCHAR(10)  NULL,
    collision_date       VARCHAR(30)  NULL,
    collision_time       VARCHAR(30)  NULL,
    longitude            VARCHAR(30)  NULL,   -- note the order: see Step 2
    latitude             VARCHAR(30)  NULL,
    severity_code        VARCHAR(10)  NULL,
    severity_label       VARCHAR(100) NULL,
    road_surface_code    VARCHAR(10)  NULL,
    weather_code         VARCHAR(10)  NULL,
    urban_rural_code     VARCHAR(10)  NULL
    -- ... every remaining source column, unchanged
);
```

Three deliberate choices here:

1. **`NULL` on every column.** If the CSV can contain an empty field, the table must
   accept it. A `NOT NULL` staging column that meets an empty string aborts the load —
   exactly the failure you are trying to avoid.
2. **No conversion at this point.** No dates, no integers. Staging is a mirror.
3. **`DROP TABLE IF EXISTS` before `CREATE`.** The load should be re-runnable from
   scratch. A pipeline you cannot rerun is a pipeline you cannot trust after a failure.

!!! warning "Do not truncate a staging table you have not validated yet"

    `TRUNCATE TABLE` is fine for the reload itself. It is not fine as a substitute for
    checking the previous load — once truncated, the evidence is gone. Validate first,
    then reload. See [Step 5](#step-5-reconcile-control-totals-between-the-stages).

---

## Step 2 — Verify column order before a positional bulk load

This is the step that separates a pipeline that works from one that is *quietly wrong*,
and it costs you thirty seconds.

`BULK INSERT` maps fields **by position**, not by name. If the CSV column order differs
from your table definition, values land in the wrong columns — and SQL Server will not
necessarily complain. Text goes into a text column, so the load succeeds, the row counts
match, and your latitude is now sitting in a severity column. Every downstream
conversion still "works". Nothing raises an error. The data is simply wrong.

So compare the file header against your table definition before loading:

```sql
-- What the table expects, in order
SELECT c.column_id, c.name
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID('stg.Collisions')
ORDER BY c.column_id;
```

```powershell
# What the file actually contains, in order
Get-Content .\collisions_clean.csv -TotalCount 1
```

Then reconcile the two lists by eye, position by position. On the project this guide is
drawn from, the collision CSV placed `longitude` and `latitude` *earlier* than the
initial table definition assumed. Everything else matched, so the mismatch was one
swap — and it would have silently corrupted every geographic calculation in the
pipeline.

If the orders differ, drop and recreate the staging table to match the file. Keep the
correction as its own numbered script so the fix is version-controlled rather than
living in someone's memory.

!!! tip "Why not just use a format file?"

    A format file removes the positional risk and is the right answer for a stable,
    long-lived load. I still verify the header even when one exists, because the format
    file is only correct until somebody regenerates the source export without telling
    you. Verification that is cheap and runs every time beats configuration that is
    correct only until it isn't.

---

## Step 3 — Bulk-load the CSV into staging

```sql
TRUNCATE TABLE stg.Collisions;

BULK INSERT stg.Collisions
FROM 'C:\SQLData\RoadAccidentData\collisions_clean.csv'
WITH
(
    FORMAT         = 'CSV',
    FIRSTROW       = 2,          -- skip the header row
    FIELDQUOTE     = '"',        -- respect quoted fields containing commas
    CODEPAGE       = '65001',    -- read the file as UTF-8
    ROWTERMINATOR  = '0x0A',     -- LF line endings
    TABLOCK
);
```

The options that matter:

| Option | Why it is there |
| --- | --- |
| `FIRSTROW = 2` | Without it, your header row becomes a data row |
| `FIELDQUOTE = '"'` | A quoted field containing a comma is otherwise split into two columns, shifting everything after it |
| `CODEPAGE = '65001'` | UTF-8. Omit it and non-ASCII characters arrive mangled, which you discover weeks later |
| `ROWTERMINATOR = '0x0A'` | Files exported on Linux/macOS end lines with LF, not CRLF. Getting this wrong merges rows |
| `TABLOCK` | Bulk-load efficiency; also takes a table-level lock, which is fine for a dedicated staging table |

!!! warning "A successful `BULK INSERT` proves nothing about correctness"

    It proves SQL Server could read the file and find the columns. Given a column-order
    mismatch, it proves nothing else. This is why Step 2 exists and why Step 5 follows.

Repeat for each additional file. If your sources are related — a parent file and one or
more child files — load all of them before moving to the typed layer, so the
reconciliation in Step 5 can be run as a single comparison.

---

## Step 4 — Convert into typed tables with `TRY_CONVERT`

Now build the real tables. Note what each column becomes:

| Staging (text) | Typed | Conversion note |
| --- | --- | --- |
| `collision_index` | `VARCHAR(20)` | The business key — keep it as text, never as an integer |
| `collision_date` | `DATE` | `TRY_CONVERT(..., 23)` for ISO `yyyy-mm-dd` |
| `collision_time` | `TIME(0)` | Second precision is enough; store no fractional seconds you do not have |
| `latitude` / `longitude` | `DECIMAL(9,6)` | Six decimal places is roughly 11 cm — far beyond the source precision |
| `collision_year`, `severity_code` | `SMALLINT` / `TINYINT` | Codes are integers; do not store them as text |
| `severity_label` | `NVARCHAR(100)` | Readable labels for the reporting layer |

Then insert with an explicit column list on **both** sides — never `INSERT INTO ... SELECT *`:

```sql
INSERT INTO dbo.Collisions
(
    collision_index, collision_year, collision_date, collision_time,
    longitude, latitude, severity_code, severity_label,
    road_surface_code, weather_code, urban_rural_code
)
SELECT
    CAST(NULLIF(TRIM(collision_index), '') AS VARCHAR(20)),
    TRY_CONVERT(SMALLINT,     NULLIF(TRIM(collision_year), '')),
    TRY_CONVERT(DATE,         NULLIF(TRIM(collision_date), ''), 23),
    TRY_CONVERT(TIME(0),      NULLIF(TRIM(collision_time), '')),
    TRY_CONVERT(DECIMAL(9,6), NULLIF(TRIM(longitude), '')),
    TRY_CONVERT(DECIMAL(9,6), NULLIF(TRIM(latitude), '')),
    TRY_CONVERT(TINYINT,      NULLIF(TRIM(severity_code), '')),
    NULLIF(TRIM(severity_label), ''),
    TRY_CONVERT(TINYINT,      NULLIF(TRIM(road_surface_code), '')),
    TRY_CONVERT(TINYINT,      NULLIF(TRIM(weather_code), '')),
    TRY_CONVERT(TINYINT,      NULLIF(TRIM(urban_rural_code), ''))
FROM stg.Collisions;
```

Every line is doing the same two-part job, and both halves are load-bearing:

- **`NULLIF(TRIM(col), '')`** — turns whitespace-only strings into `NULL`. Without it, a
  field containing a single space is "present" and `TRY_CONVERT(' ', SMALLINT)` returns
  `NULL` anyway, but a field containing `'  '` in a `VARCHAR` column would silently
  survive as a value that sorts and groups as its own category.
- **`TRY_CONVERT`** — returns `NULL` on failure instead of aborting the insert. The load
  finishes; the bad values become countable.

!!! danger "`TRY_CONVERT` hides errors unless you go looking for them"

    This is the trade-off, stated plainly. `TRY_CONVERT` converts a hard failure into a
    soft one, which is exactly what you want for resilience — and exactly what makes a
    silent data-loss bug possible. The mitigation is not to avoid `TRY_CONVERT`; it is
    to count the `NULL`s it produces. Step 5 does that. **Never skip Step 5.**

Then add the primary keys — the business key for the parent, and a composite key for each
child, because child references are typically unique only *within* a parent:

```sql
ALTER TABLE dbo.Collisions
    ADD CONSTRAINT PK_Collisions PRIMARY KEY CLUSTERED (collision_index);
GO

-- vehicle_reference restarts at 1 for every collision, so it is not globally unique.
-- Combining it with the parent key produces a key that is.
ALTER TABLE dbo.Vehicles
    ADD CONSTRAINT PK_Vehicles PRIMARY KEY CLUSTERED (collision_index, vehicle_reference);
```

!!! tip "Why composite keys instead of a surrogate `IDENTITY` column"

    A surrogate integer key is easier to join on and is often the right call. I use the
    composite natural key here because it stays traceable back to the source file — when
    a row looks wrong, you can find its origin without a mapping table. For a pipeline
    that ends in a deployed reporting model, an `IDENTITY` surrogate plus a unique
    constraint on the natural key is the more common professional choice, and it is what
    I would reach for if the model grew past a handful of tables.

---

## Step 5 — Reconcile control totals between the stages

This is the step that makes the whole pattern worth building. Compare what arrived
against what survived:

```sql
SELECT
    'Collisions' AS table_name,
    (SELECT COUNT_BIG(*) FROM stg.Collisions) AS staging_rows,
    (SELECT COUNT_BIG(*) FROM dbo.Collisions) AS typed_rows
UNION ALL
SELECT
    'Vehicles',
    (SELECT COUNT_BIG(*) FROM stg.Vehicles),
    (SELECT COUNT_BIG(*) FROM dbo.Vehicles)
UNION ALL
SELECT
    'Casualties',
    (SELECT COUNT_BIG(*) FROM stg.Casualties),
    (SELECT COUNT_BIG(*) FROM dbo.Casualties);
```

**Rule: `staging_rows` must equal `typed_rows`.** The typed insert has no `WHERE` clause,
so no row may be dropped. If the two differ, something in the load is losing records and
you must fix it before touching a dashboard.

Row counts alone are not enough though, because a row can arrive intact and still be
broken *inside*. Count the `NULL`s that `TRY_CONVERT` created, per convertible column:

```sql
SELECT
    SUM(CASE WHEN collision_date IS NULL AND NULLIF(TRIM(s.collision_date), '') IS NOT NULL THEN 1 ELSE 0 END) AS bad_date,
    SUM(CASE WHEN collision_year IS NULL AND NULLIF(TRIM(s.collision_year), '') IS NOT NULL THEN 1 ELSE 0 END) AS bad_year,
    SUM(CASE WHEN latitude       IS NULL AND NULLIF(TRIM(s.latitude),       '') IS NOT NULL THEN 1 ELSE 0 END) AS bad_latitude,
    SUM(CASE WHEN longitude      IS NULL AND NULLIF(TRIM(s.longitude),      '') IS NOT NULL THEN 1 ELSE 0 END) AS bad_longitude
FROM stg.Collisions AS s;
```

The `AND ... IS NOT NULL` half is what makes this a *quality* check rather than a
*completeness* check. It counts only values that were **present in the source and failed
to convert** — genuinely malformed data — while ignoring fields that were legitimately
empty. Without it, a nullable column looks permanently broken and you stop trusting the
report.

Run this on every load. A non-zero result is not automatically a blocker, but it must be
a **decision**: either the row is excluded with a documented reason, or the value is
repaired upstream in the preparation script. What you must never do is notice the number
and say nothing.

---

## Step 6 — Check keys and referential integrity

Confirm uniqueness, then confirm that every child row has a parent:

```sql
-- Uniqueness and completeness of the parent key
SELECT
    COUNT_BIG(*)                                        AS total_rows,
    COUNT(DISTINCT collision_index)                     AS unique_keys,
    SUM(CASE WHEN NULLIF(TRIM(collision_index), '') IS NULL THEN 1 ELSE 0 END) AS missing_keys
FROM stg.Collisions;
```

```sql
-- Orphans: vehicles with no matching collision
SELECT COUNT_BIG(*) AS vehicles_without_collision
FROM dbo.Vehicles AS v
LEFT JOIN dbo.Collisions AS c
    ON v.collision_index = c.collision_index
WHERE c.collision_index IS NULL;
```

Expected results, and what a deviation means:

| Measure | Expected | If it is wrong |
| --- | --- | --- |
| `unique_keys` = `total_rows` | Always | Duplicate keys — the source or the load is duplicating records |
| `missing_keys` | 0 | Records that cannot be linked to anything; usually a parsing failure |
| Orphan count | 0 | Either a genuine source defect or a truncated load. Investigate before proceeding |

An orphan count above zero is the check most often skipped, and it is the one that
catches a partial load that reconciliation-by-count missed because the counts happened
to line up across two different parent files.

---

## Step 7 — Enforce the relationships and index the access paths

Only now that the data is proven valid does it make sense to let the database enforce it.
Creating foreign keys first and loading second means debugging two problems at once.

```sql
ALTER TABLE dbo.Vehicles
    ADD CONSTRAINT FK_Vehicles_Collisions
    FOREIGN KEY (collision_index) REFERENCES dbo.Collisions (collision_index);
GO

ALTER TABLE dbo.Casualties
    ADD CONSTRAINT FK_Casualties_Collisions
    FOREIGN KEY (collision_index) REFERENCES dbo.Collisions (collision_index);
GO

-- Then confirm the engine actually checked the existing data
SELECT
    fk.name            AS foreign_key,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys AS fk;
```

!!! tip "Read `is_not_trusted`, not just `is_disabled`"

    A foreign key can be **enabled** and still be **untrusted**. `is_disabled = 0` means
    the constraint is enforced on future writes; `is_not_trusted = 1` means the engine
    never validated the rows that were already there. Both must be `0`. This distinction
    is invisible unless you query for it, and it is the difference between a constraint
    that protects your data and one that only decorates the schema.

Index the columns you actually join and filter on — not every column:

```sql
CREATE NONCLUSTERED INDEX IX_Vehicles_CollisionIndex
    ON dbo.Vehicles (collision_index)
    INCLUDE (vehicle_type_label);

CREATE NONCLUSTERED INDEX IX_Collisions_Year_Severity
    ON dbo.Collisions (collision_year, severity_code);
```

Every index is a trade: faster reads on that path, extra storage, and slower writes. Add
them for measured access patterns, and be ready to justify each one.

---

## Step 8 — Expose reporting views with a declared grain

Your BI tool should never see the staging layer, and ideally not the base tables either.
Publish views that each declare what one row means:

```sql
CREATE OR ALTER VIEW dbo.vw_CasualtyAnalysis
AS
SELECT
    ca.casualty_key,
    ca.vehicle_key,
    ca.collision_index,
    c.collision_year,
    c.collision_date,
    ca.casualty_severity_label,
    v.vehicle_type_label,
    c.weather_conditions_label,
    c.road_surface_conditions_label,
    c.latitude,
    c.longitude
FROM dbo.Casualties  AS ca
INNER JOIN dbo.Collisions AS c ON ca.collision_index = c.collision_index
LEFT  JOIN dbo.Vehicles   AS v ON ca.vehicle_key     = v.vehicle_key;
GO
```

Three views — one row per collision, one row per vehicle, one row per casualty — not one
wide joined table. The reason is arithmetic, not aesthetics:

> A collision with five casualties appears **once** in the collision view and **five
> times** in the casualty view. Count rows in the wrong view and your collision total is
> inflated by a factor nobody notices, because the number still looks plausible.

Declare the grain in the view name, in a header comment, and in your reporting model.
Then let each metric be calculated from the table whose grain matches it — a collision
count from the collision view, a casualty count from the casualty view. If you must count
collisions from within a casualty-grain visual, use `COUNT(DISTINCT collision_index)`, and
know that you have chosen a slower, more fragile query to avoid a modelling fix.

---

## Troubleshooting

**`BULK INSERT` fails with "cannot open file" or an access-denied error**

Not a permissions problem on *your* account — a permissions problem on the *service*
account. `BULK INSERT` executes as the SQL Server service identity, which does not
inherit your personal folder access. Copy the files somewhere neutral and grant the
service account read permission:

```powershell
# Move the files out of a personal profile path
New-Item -ItemType Directory -Force -Path C:\SQLData\RoadAccidentData | Out-Null
Copy-Item .\collisions_clean.csv C:\SQLData\RoadAccidentData\ -Force

# Grant read to the database service account (MSSQLSERVER for a default instance)
icacls C:\SQLData\RoadAccidentData /grant "NT SERVICE\MSSQLSERVER:(OI)(CI)(RX)"
```

Keep the path short and local. Network shares and user-profile paths add failure modes
you do not need.

**Row counts match but the data is clearly wrong**

Go back to Step 2. A positional mismatch produces exactly this signature: every count
reconciles, every conversion succeeds, and the values are in the wrong columns. Compare
the file header to `sys.columns` in order, side by side.

**Everything converts to `NULL` in one column**

Check the `ROWTERMINATOR`. A CRLF file read with `ROWTERMINATOR = '0x0A'` leaves a stray
carriage return on the last field of each line, which then fails every type conversion
while the row itself still lands. `SELECT TOP 5` from the staging table and look at the
raw text — the staging layer exists precisely so you can see the bytes as they arrived.

**The dashboard's totals are inflated compared to SQL**

You are counting from the wrong grain — see Step 8. Compare the measure against a direct
`COUNT_BIG(*)` on the corresponding view; if they differ, the measure is reading a
many-side table.

---

## Verifying you are done

- [ ] Staging and typed row counts match for **every** table
- [ ] Conversion-failure counts are zero, or every non-zero value has a documented decision
- [ ] `COUNT(DISTINCT key)` equals total rows for each entity
- [ ] Orphan checks return zero for every child table
- [ ] All foreign keys report `is_disabled = 0` **and** `is_not_trusted = 0`
- [ ] Views are created and their grain is documented
- [ ] The whole sequence reruns cleanly from an empty database

That last point is the real test. A pipeline that works once on your machine is a
demonstration; a pipeline that rebuilds from scratch is a system.

---

## Where this pattern does not apply

Being explicit about the limits of my own guidance:

- **Streaming or continuously arriving data** needs the same ideas — landing zone,
  typed layer, reconciliation — but implemented with incremental loads and load-audit
  rows rather than truncate-and-reload. This guide describes the batch case.
- **Files under a few thousand rows** rarely justify two layers. Load them typed and
  handle failures in code; the ceremony is not free.
- **Strongly typed, well-governed sources** (a well-designed API, a managed warehouse
  table) already provide what staging provides. Staging exists to absorb *unpredictable*
  input.
- **True exposure-adjusted analysis** needs denominators this pipeline does not contain.
  Row counts answer "where did more events occur"; they do not answer "where was risk
  higher". Those are different questions and the second one needs traffic volume,
  population, or similar data. I have deliberately not implied otherwise.

---

*This guide documents a pipeline I designed and built: 503,475 collisions, 640,522
casualties, and 920,692 vehicles across five years of public UK road-safety data, loaded
into a validated SQL Server model with trusted foreign keys, then reported in Power BI.
Every reconciliation result quoted here is a check that was actually run on that data.*

*Doc type: how-to guide. Related samples: [API reference](index.md) (planned),
[concept explainer](index.md) (planned).*