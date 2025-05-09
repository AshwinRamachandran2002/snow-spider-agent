/* -----------------------------------------------------------------
   CPC technology areas (level‑4 groups) whose German patents
   granted in December‑2016 show the highest exponential moving
   average (α = 0.1) of yearly patent‑filing counts.

   Output columns :
        • full_title  – complete CPC title
        • cpc_group   – level‑4 CPC group symbol (e.g. F16K31/00)
        • best_year   – year in which EMA peaks
------------------------------------------------------------------*/

WITH RECURSIVE
/* 1.  German patents granted in Dec‑2016 and their CPC codes */
subset AS (
    SELECT
        p."filing_date"                                  AS filing_date_num,   -- yyyymmdd (NUMBER)
        f.value:"code"::STRING                           AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS  AS p,
         LATERAL FLATTEN (INPUT => p."cpc") AS f
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),
/* 2.  Build CPC *group* code (“…/00”) and extract filing year */
group_codes AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE(filing_date_num::STRING,'YYYYMMDD')) AS filing_year,
        UPPER(REGEXP_REPLACE(cpc_code,'/.*','')) || '/00'              AS group_code
    FROM subset
    WHERE cpc_code IS NOT NULL AND cpc_code <> ''
),
/* 3.  Yearly filing counts per CPC group */
yearly_counts AS (
    SELECT
        group_code,
        filing_year,
        COUNT(*) AS filings
    FROM group_codes
    GROUP BY group_code, filing_year
),
/* 4.  Order years within each group to drive recursive EMA */
ordered AS (
    SELECT
        group_code,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY group_code ORDER BY filing_year) AS rn
    FROM yearly_counts
),
/* 5.  Recursive EMA : EMAₜ = 0.1·xₜ + 0.9·EMAₜ₋₁ */
ema_calc AS (
      /* initial year for each group */
      SELECT
          group_code,
          filing_year,
          filings,
          rn,
          CAST(filings AS FLOAT) AS ema
      FROM ordered
      WHERE rn = 1

      UNION ALL

      /* subsequent years */
      SELECT
          o.group_code,
          o.filing_year,
          o.filings,
          o.rn,
          0.1 * o.filings + 0.9 * e.ema AS ema
      FROM ordered   AS o
      JOIN ema_calc AS e
        ON o.group_code = e.group_code
       AND o.rn        = e.rn + 1
),
/* 6.  Year with highest EMA for every CPC group */
best_years AS (
    SELECT
        group_code,
        filing_year            AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY group_code
                           ORDER BY ema DESC, filing_year) AS rk
    FROM ema_calc
)
/* 7.  Attach CPC definition title & present results */
SELECT
    COALESCE(d."titleFull", '(title not found)')  AS "full_title",
    b.group_code                                  AS "cpc_group",
    b.best_year                                   AS "best_year"
FROM best_years  AS b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION AS d
       ON d."symbol" = b.group_code
WHERE b.rk = 1                         -- highest EMA per group
ORDER BY "full_title" ASC NULLS LAST, "cpc_group";