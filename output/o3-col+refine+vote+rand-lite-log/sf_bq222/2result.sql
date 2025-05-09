/*  ---------------------------------------------------------------
    Identify every 4–character CPC technology area that appears in
    German patents granted during December-2016, compute the yearly
    exponential-moving-average (α = 0.1) of German patent-filing
    counts for each such CPC group, and return the year in which
    that EMA peaks together with the CPC’s full title.
    --------------------------------------------------------------- */
WITH

/* 1. 4-character CPC groups present in DE grants of Dec-2016 */
target_groups AS (
    SELECT DISTINCT
           LEFT(c.value:"code"::STRING, 4) AS cpc_group
    FROM   PATENTS.PATENTS.PUBLICATIONS  p,
           LATERAL FLATTEN (INPUT => p."cpc") c
    WHERE  p."country_code" = 'DE'
      AND  p."grant_date"   BETWEEN 20161201 AND 20161231
),

/* 2. Yearly filing counts (DE only) for those CPC groups */
filings AS (
    SELECT
        LEFT(c.value:"code"::STRING, 4)      AS cpc_group,
        FLOOR(p."filing_date" / 10000)       AS year,
        COUNT(*)                             AS x
    FROM   PATENTS.PATENTS.PUBLICATIONS  p,
           LATERAL FLATTEN (INPUT => p."cpc") c
    WHERE  p."country_code" = 'DE'
      AND  LEFT(c.value:"code"::STRING, 4) IN (SELECT cpc_group FROM target_groups)
    GROUP BY 1, 2
),

/* 3. Impose a sequential order of years within each group */
ordered AS (
    SELECT
        cpc_group,
        year,
        x,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY year) AS rn
    FROM filings
),

/* 4. Recursive EMA calculation with α = 0.1  (EMAₜ = 0.1·xₜ + 0.9·EMAₜ₋₁) */
ema_cte (cpc_group, year, x, rn, ema) AS (
        -- anchor (first year for each group)
        SELECT cpc_group,
               year,
               x,
               rn,
               x * 0.10                   -- EMA₁
        FROM   ordered
        WHERE  rn = 1

        UNION ALL

        -- recursive step
        SELECT o.cpc_group,
               o.year,
               o.x,
               o.rn,
               (o.x * 0.10) + (e.ema * 0.90)
        FROM   ema_cte  e
        JOIN   ordered  o
          ON   o.cpc_group = e.cpc_group
         AND   o.rn        = e.rn + 1
),

/* 5. Pick the single year with the highest EMA for each CPC group */
best_years AS (
    SELECT
        cpc_group,
        year             AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY ema DESC) AS rk
    FROM ema_cte
),

/* 6. Map each 4-char CPC group to its full title */
titles AS (
    SELECT
        d."symbol"  AS cpc_group,
        d."titleFull" AS cpc_title
    FROM PATENTS.PATENTS.CPC_DEFINITION d
    WHERE LENGTH(d."symbol") = 4          -- only the 4-char group rows
)

/* 7. Final result */
SELECT
       t.cpc_title,
       b.cpc_group,
       b.best_year
FROM   best_years b
JOIN   titles     t ON t.cpc_group = b.cpc_group
WHERE  b.rk = 1                 -- keep the peak-EMA year per group
ORDER  BY b.ema DESC NULLS LAST;