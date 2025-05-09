WITH RECURSIVE
/*---------------------------------------------------------------------------
1)  Patents granted in Germany during December-2016 and all their CPC codes
---------------------------------------------------------------------------*/
filtered_pub AS (
    SELECT
        p."publication_number",
        p."filing_date",
        cp.value:"code"::string AS full_cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."cpc") AS cp
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
      AND cp.value IS NOT NULL
      AND p."filing_date" > 0
),
/*---------------------------------------------------------------------------
2)  Convert each detailed CPC code to its level-4 main-group form
     e.g.  H04L9/0844  →  H04L9/08
---------------------------------------------------------------------------*/
lvl4_groups AS (
    SELECT
        "publication_number",
        "filing_date",
        REGEXP_REPLACE(
            full_cpc_code,
            '^([^/]+)/([0-9]{2}).*',
            '\\1/\\2'
        ) AS cpc_group
    FROM filtered_pub
),
/*---------------------------------------------------------------------------
3)  Yearly filing counts for every level-4 CPC group
---------------------------------------------------------------------------*/
year_counts AS (
    SELECT
        cpc_group,
        FLOOR("filing_date" / 10000) AS filing_year,
        COUNT(DISTINCT "publication_number") AS filings
    FROM lvl4_groups
    GROUP BY cpc_group, FLOOR("filing_date" / 10000)
),
ordered AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM year_counts
),
/*---------------------------------------------------------------------------
4)  Recursive computation of the exponential moving average (α = 0.1)
---------------------------------------------------------------------------*/
ema_calc AS (
    /* base year per CPC group */
    SELECT
        cpc_group,
        filing_year,
        filings,
        filings AS ema,
        rn
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* subsequent years */
    SELECT
        o.cpc_group,
        o.filing_year,
        o.filings,
        0.1 * o.filings + 0.9 * e.ema AS ema,
        o.rn
    FROM ema_calc AS e
    JOIN ordered   AS o
      ON o.cpc_group = e.cpc_group
     AND o.rn       = e.rn + 1
),
/*---------------------------------------------------------------------------
5)  For every CPC group, keep the year with the highest EMA
---------------------------------------------------------------------------*/
max_ema_year AS (
    SELECT
        cpc_group,
        filing_year                AS year_of_max_ema,
        ema,
        ROW_NUMBER() OVER (
            PARTITION BY cpc_group
            ORDER BY ema DESC, filing_year
        ) AS rk
    FROM ema_calc
)
/*---------------------------------------------------------------------------
6)  Attach CPC titles (if available) and return the result
---------------------------------------------------------------------------*/
SELECT
    COALESCE(cd."titleFull", 'N/A') AS cpc_full_title,
    m.cpc_group                     AS cpc_group,
    m.year_of_max_ema               AS year_with_highest_ema
FROM max_ema_year AS m
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION AS cd
       ON cd."symbol" = m.cpc_group
WHERE m.rk = 1
ORDER BY m.ema DESC NULLS LAST;