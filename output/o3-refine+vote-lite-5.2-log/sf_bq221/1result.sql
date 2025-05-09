/* ---------------------------------------------------------------------------
   Identify, for every CPC technology group (level‑5), the calendar year that
   attains the highest exponential‑moving‑average (α = 0.2) of patent filings.
   ---------------------------------------------------------------------------
   Main changes versus previous attempt
   ------------------------------------
   • Take the FIRST CPC code by array position instead of relying on the
     “first = true” flag (which is not present on every record).
   • Keep the inner logic identical but make the join to CPC_DEFINITION LEFT‑
     JOIN so results are returned even when the CPC title is missing; this
     avoids the “No data found” situation.
   ------------------------------------------------------------------------- */
WITH
/* 1.  One CPC code (the first in the list) per publication that has a filing
       date and a non‑empty application number                                        */
first_cpc AS (
    SELECT
        p."publication_number",
        p."application_number",
        p."filing_date",
        TRIM( c.value:"code"::string )                  AS cpc_code
    FROM  PATENTS.PATENTS.PUBLICATIONS  p,
          LATERAL FLATTEN( INPUT => p."cpc") c
    WHERE  p."application_number" IS NOT NULL
      AND  p."application_number" <> ''
      AND  p."filing_date"        IS NOT NULL
      AND  p."filing_date"        > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                               ORDER BY c.index) = 1  -- first element only
),

/* 2.  Convert each CPC symbol to its level‑5 “/00” group
       (e.g.  H04L9/08  →  H04L9/00) and build annual filing counts            */
yearly_counts AS (
    SELECT
        CONCAT( SPLIT_PART(cpc_code,'/',1) , '/00')     AS group_code,
        EXTRACT( YEAR
                 FROM TO_DATE( "filing_date"::string , 'YYYYMMDD'))        AS yr,
        COUNT(*)                                        AS filings
    FROM first_cpc
    GROUP BY group_code, yr
),

/* 3.  Rank years within each CPC group to enable the recursive EMA           */
ranked AS (
    SELECT
        group_code,
        yr,
        filings,
        ROW_NUMBER() OVER (PARTITION BY group_code ORDER BY yr)  AS rn
    FROM yearly_counts
),

/* 4.  Recursive EMA (α = 0.2)                                                */
ema_recursive AS (
    -- seed
    SELECT
        group_code,
        yr,
        filings,
        CAST(filings AS DOUBLE)                      AS ema,
        rn
    FROM ranked
    WHERE rn = 1
    UNION ALL
    -- recursion
    SELECT
        r.group_code,
        r.yr,
        r.filings,
        0.2 * r.filings + 0.8 * e.ema               AS ema,
        r.rn
    FROM ema_recursive e
    JOIN ranked      r
      ON r.group_code = e.group_code
     AND r.rn        = e.rn + 1
),

/* 5.  Select, for every CPC group, the year that delivers the highest EMA    */
best_year_per_group AS (
    SELECT
        group_code,
        yr      AS best_year,
        ema     AS max_ema,
        ROW_NUMBER() OVER (PARTITION BY group_code
                           ORDER BY ema DESC, yr) AS rk
    FROM ema_recursive
    QUALIFY rk = 1
)

/* 6.  Attach the full CPC title (level‑5) – use LEFT JOIN so that groups
       without a matching title are still reported                            */
SELECT
    b.group_code                       AS cpc_group_code,
    cd."titleFull"                     AS cpc_title,
    b.best_year,
    b.max_ema
FROM best_year_per_group  b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = b.group_code
      AND cd."level"  = 5
ORDER BY cpc_title NULLS LAST, cpc_group_code;