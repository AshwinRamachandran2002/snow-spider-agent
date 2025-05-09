/*  Highest EMA (α = 0.2) of yearly patent filings per CPC level‑5 group,
    together with the corresponding “best year” and CPC title               */

WITH RECURSIVE
/* -------------------------------------------------------------------- 1
   Select patents with filing‑date & application number, take the FIRST
   CPC code, and collapse it to level‑5 (everything before the slash).
------------------------------------------------------------------------ */
first_cpc AS (
    SELECT
        REGEXP_REPLACE(UPPER(f.value:"code"::STRING), '/.*', '')  AS cpc_group,
        TO_NUMBER(LEFT(TO_VARCHAR(p."filing_date"), 4))          AS filing_year
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."cpc") AS f
    WHERE p."filing_date"        > 0
      AND p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND f.index = 0                         -- only the first CPC code
),
/* -------------------------------------------------------------------- 2   yearly filings */
yearly_counts AS (
    SELECT
        cpc_group,
        filing_year,
        COUNT(*) AS filings
    FROM first_cpc
    WHERE filing_year IS NOT NULL
    GROUP BY cpc_group, filing_year
),
/* -------------------------------------------------------------------- 3   rank years */
ranked_counts AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM yearly_counts
),
/* -------------------------------------------------------------------- 4   recursive EMA (α = 0.2) */
ema_cte AS (
    /* anchor */
    SELECT
        cpc_group,
        filing_year,
        filings,
        CAST(filings AS DOUBLE) AS ema,
        rn
    FROM ranked_counts
    WHERE rn = 1

    UNION ALL

    /* recursive step */
    SELECT
        r.cpc_group,
        r.filing_year,
        r.filings,
        0.2 * r.filings + 0.8 * e.ema  AS ema,
        r.rn
    FROM ema_cte       e
    JOIN ranked_counts r
      ON r.cpc_group = e.cpc_group
     AND r.rn        = e.rn + 1
),
/* -------------------------------------------------------------------- 5   best (max‑EMA) year per group */
best_year_per_group AS (
    SELECT
        cpc_group,
        filing_year   AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY ema DESC) AS rn
    FROM ema_cte
),
/* -------------------------------------------------------------------- 6   CPC titles (level‑5) */
cpc_titles AS (
    SELECT
        REGEXP_REPLACE("symbol", '/.*', '')          AS cpc_group,
        MAX("titleFull")                             AS title_full
    FROM PATENTS.PATENTS.CPC_DEFINITION
    GROUP BY REGEXP_REPLACE("symbol", '/.*', '')
)
/* -------------------------------------------------------------------- final result */
SELECT
    b.cpc_group                      AS "CPC_GROUP_LVL5",
    COALESCE(t.title_full, 'UNKNOWN') AS "CPC_TITLE",
    b.best_year                      AS "BEST_YEAR",
    ROUND(b.ema, 4)                  AS "MAX_EMA"
FROM best_year_per_group b
LEFT JOIN cpc_titles      t  ON t.cpc_group = b.cpc_group
WHERE b.rn = 1
ORDER BY b.ema DESC NULLS LAST, b.cpc_group;