/*  ------------------------------------------------------------
    1)  Pick German patents that were granted in December 2016
    2)  Expand every CPC code the patent carries and keep its
        level‑4 group (first four characters, e.g. H04L)
    3)  Count yearly filings per CPC‑level‑4 group
    4)  For every group, calculate the Exponential Moving Average
        (α = 0.1) across the years with a recursive CTE
    5)  Keep, for every group, the year that shows the highest EMA
    6)  Attach the full CPC title taken from PATENTS.PATENTS.CPC_DEFINITION
-----------------------------------------------------------------*/
WITH RECURSIVE
/* ---------- 1. Publications granted in Dec‑2016 (Germany) ---------- */
filtered_publications AS (
    SELECT
        p."publication_number",
        p."filing_date",
        p."cpc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
      AND p."filing_date" > 0            -- ignore missing dates
),

/* ---------- 2. Yearly filing counts per CPC level‑4 group ---------- */
filings_per_year_group AS (
    SELECT
        LEFT( (cpc_item.value:"code")::STRING , 4 )                               AS cpc_group,
        EXTRACT( YEAR FROM TO_DATE(p."filing_date"::STRING,'YYYYMMDD') )          AS filing_year,
        COUNT(DISTINCT p."publication_number")                                    AS filings
    FROM filtered_publications  p,
         LATERAL FLATTEN(INPUT => p."cpc") cpc_item
    GROUP BY 1,2
),

/* ---------- 3. Add an ordering index for recursion ---------- */
ordered_counts AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM filings_per_year_group
),

/* ---------- 4. Recursive EMA calculation (α = 0.1) ---------- */
ema_calc AS (
    /* ----- Anchor member : first year for each group ----- */
    SELECT
        cpc_group,
        filing_year,
        filings::FLOAT                      AS filings,
        filings::FLOAT                      AS ema,         -- ema₁ = count₁
        rn
    FROM ordered_counts
    WHERE rn = 1

    UNION ALL

    /* ----- Recursive member ----- */
    SELECT
        oc.cpc_group,
        oc.filing_year,
        oc.filings::FLOAT,
        0.1 * oc.filings + 0.9 * ec.ema     AS ema,
        oc.rn
    FROM ema_calc ec
    JOIN ordered_counts oc
      ON oc.cpc_group = ec.cpc_group
     AND oc.rn        = ec.rn + 1
),

/* ---------- 5. Pick the best year (highest EMA) per group ---------- */
best_year_per_group AS (
    SELECT
        cpc_group,
        filing_year,
        ema,
        RANK() OVER (PARTITION BY cpc_group ORDER BY ema DESC) AS rnk
    FROM ema_calc
)

/* ---------- 6. Final selection with CPC titles ---------- */
SELECT
    d."titleFull"                           AS "CPC_Title",
    b.cpc_group                             AS "CPC_Group",
    b.filing_year                           AS "Best_Year"
FROM best_year_per_group b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON LEFT(d."symbol", 4) = b.cpc_group     -- attach full title
WHERE b.rnk = 1                                 -- highest EMA only
ORDER BY b.cpc_group;