/* -------------------------------------------------------------------------
   CPC level-5 groups with the highest exponential moving average (α = 0.2)
   of yearly patent filings.  Only the first CPC code per publication that
   has a valid filing date and non-empty application number is considered.
---------------------------------------------------------------------------*/
WITH RECURSIVE

/* 1) First CPC code for each publication ----------------------------------*/
first_cpc AS (
    SELECT
        p."publication_number",
        FLOOR(p."filing_date" / 10000)                       AS filing_year,   -- YYYY
        f.value:"code"::STRING                               AS cpc_code,
        ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                           ORDER BY f.index)                 AS rn
    FROM PATENTS.PATENTS.PUBLICATIONS  AS p,
         LATERAL FLATTEN(input => p."cpc") AS f
    WHERE p."application_number" IS NOT NULL
      AND TRIM(p."application_number") <> ''
      AND p."filing_date" IS NOT NULL
),

first_cpc_only AS (          -- keep only the very first CPC code
    SELECT *
    FROM   first_cpc
    WHERE  rn = 1
),

/* 2) Map each CPC code to its level-5 CPC group ---------------------------*/
cpc_level5 AS (
    SELECT
        fc.filing_year,
        d5."symbol"      AS cpc_group,        -- e.g. H04L
        d5."titleFull"   AS cpc_title
    FROM   first_cpc_only                  AS fc
    JOIN   PATENTS.PATENTS.CPC_DEFINITION  AS d5
           ON  d5."level" = 5
           AND POSITION(d5."symbol", fc.cpc_code) = 1   -- prefix match
),

/* 3) Yearly filing counts per CPC group -----------------------------------*/
yearly_counts AS (
    SELECT
        cpc_group,
        cpc_title,
        filing_year                          AS year,
        COUNT(*)                             AS n_filings
    FROM   cpc_level5
    GROUP  BY cpc_group, cpc_title, filing_year
),

/* 4) Rank the years chronologically for each group ------------------------*/
ranked_years AS (
    SELECT
        cpc_group,
        cpc_title,
        year,
        n_filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY year) AS rn
    FROM   yearly_counts
),

/* 5) Recursive EMA calculation (α = 0.2) ----------------------------------*/
ema_cte AS (
    /* seed: first year of each group */
    SELECT
        cpc_group,
        cpc_title,
        year,
        n_filings,
        rn,
        n_filings::FLOAT                         AS ema                 -- EMA₁ = x₁
    FROM   ranked_years
    WHERE  rn = 1

    UNION ALL

    /* recursive step: remaining years */
    SELECT
        r.cpc_group,
        r.cpc_title,
        r.year,
        r.n_filings,
        r.rn,
        0.2 * r.n_filings + 0.8 * e.ema          AS ema                 -- EMAₜ
    FROM   ema_cte        AS e
    JOIN   ranked_years   AS r
           ON r.cpc_group = e.cpc_group
          AND r.rn        = e.rn + 1
),

/* 6) Pick the best (highest EMA) year per CPC group -----------------------*/
best_year AS (
    SELECT
        cpc_group,
        cpc_title,
        year                 AS best_year,
        ema                  AS highest_ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY ema DESC, year) AS rn
    FROM   ema_cte
)

/* 7) Final result ---------------------------------------------------------*/
SELECT
    cpc_group            AS "cpc_group_level5",
    cpc_title            AS "cpc_title_full",
    best_year            AS "best_year",
    ROUND(highest_ema,4) AS "highest_ema"
FROM best_year
WHERE rn = 1
ORDER BY highest_ema DESC NULLS LAST;