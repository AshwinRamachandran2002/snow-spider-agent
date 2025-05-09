WITH
/*-------------------------------------------------*
 | 1. keep only the FIRST CPC code per publication |
 *-------------------------------------------------*/
first_cpc AS (
    SELECT
        REGEXP_SUBSTR(f.value:"code"::STRING, '^[A-Z][0-9]{2}[A-Z]') AS subclass_symbol,
        p."filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."cpc") AS f
    WHERE f.index = 0
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
      AND p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND REGEXP_SUBSTR(f.value:"code"::STRING, '^[A-Z][0-9]{2}[A-Z]') IS NOT NULL
),
/*----------------------------------------------*
 | 2. yearly filing counts for each CPC subclass|
 *----------------------------------------------*/
year_counts AS (
    SELECT
        cd."symbol"                                                AS cpc_symbol,
        cd."titleFull"                                             AS cpc_full_title,
        YEAR(TO_DATE(fc."filing_date"::STRING, 'YYYYMMDD'))        AS year,
        COUNT(*)                                                   AS yearly_count
    FROM first_cpc fc
    JOIN PATENTS.PATENTS.CPC_DEFINITION cd
      ON cd."symbol" = fc.subclass_symbol
    WHERE cd."level" = 5
    GROUP BY 1,2,3
),
/*----------------------------------------------*
 | 3. order the years within each CPC subclass  |
 *----------------------------------------------*/
ordered AS (
    SELECT
        cpc_symbol,
        cpc_full_title,
        year,
        yearly_count,
        ROW_NUMBER() OVER (PARTITION BY cpc_symbol ORDER BY year) AS rn
    FROM year_counts
),
/*----------------------------------------------*
 | 4. recursive EMA calculation (α = 0.2)       |
 *----------------------------------------------*/
ema_rec AS (
    /* seed: first year */
    SELECT
        cpc_symbol,
        cpc_full_title,
        year,
        yearly_count,
        yearly_count::FLOAT AS ema,
        rn
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* step: subsequent years */
    SELECT
        o.cpc_symbol,
        o.cpc_full_title,
        o.year,
        o.yearly_count,
        0.2 * o.yearly_count + 0.8 * r.ema AS ema,
        o.rn
    FROM ema_rec r
    JOIN ordered o
      ON o.cpc_symbol = r.cpc_symbol
     AND o.rn        = r.rn + 1
),
/*----------------------------------------------*
 | 5. pick the best EMA year per CPC subclass   |
 *----------------------------------------------*/
best_years AS (
    SELECT
        cpc_full_title,
        year                                           AS best_year,
        ROUND(ema, 4)                                  AS highest_exponential_moving_average,
        ROW_NUMBER() OVER (PARTITION BY cpc_full_title
                           ORDER BY ema DESC, year)    AS rk
    FROM ema_rec
)
SELECT
    cpc_full_title                 AS "cpc_full_title",
    best_year                      AS "best_year",
    highest_exponential_moving_average AS "highest_exponential_moving_average"
FROM best_years
WHERE rk = 1
ORDER BY cpc_full_title;