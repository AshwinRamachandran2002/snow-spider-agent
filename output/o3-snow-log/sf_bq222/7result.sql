/*  Highest EMA (α = 0.1) of German patent filings per CPC-level-4 group,
    considering patents that were granted in December-2016                */

WITH RECURSIVE

/*-------------------------------------------------------------------- 1 */
german_dec2016 AS (
    SELECT  p."publication_number",
            p."filing_date",             -- NUMBER   yyyymmdd
            p."cpc"
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."country_code"  = 'DE'
      AND   p."grant_date"    BETWEEN 20161201 AND 20161231
      AND   p."filing_date"   > 0
),

/*-------------------------------------------------------------------- 2 */
cpc_flat AS (
    SELECT  g."publication_number",
            TO_DATE(TO_VARCHAR(g."filing_date"),'YYYYMMDD') AS filing_dt,
            f.value:"code"::STRING                          AS full_cpc_code
    FROM    german_dec2016 g,
            LATERAL FLATTEN(input => g."cpc") f
),

/*-------------------------------------------------------------------- 3 */
level4_map AS (
    SELECT  cf."publication_number",
            cf.filing_dt,
            cd."symbol"     AS level4_cpc,
            cd."titleFull"  AS level4_title
    FROM    cpc_flat cf
    JOIN    PATENTS.PATENTS.CPC_DEFINITION cd
           ON cd."level" = 4
          AND cf.full_cpc_code LIKE cd."symbol" || '%'
),

/*-------------------------------------------------------------------- 4 */
yearly_counts AS (
    SELECT  level4_cpc,
            level4_title,
            EXTRACT(YEAR FROM filing_dt)                AS filing_year,
            COUNT(DISTINCT "publication_number")        AS filings
    FROM    level4_map
    GROUP BY level4_cpc, level4_title, filing_year
),

/*-------------------------------------------------------------------- 5 */
ordered AS (
    SELECT  level4_cpc,
            level4_title,
            filing_year,
            filings,
            ROW_NUMBER() OVER (PARTITION BY level4_cpc
                               ORDER BY filing_year)     AS rn
    FROM    yearly_counts
),

/*----------------------------------------------------------------
   Recursive EMA :  EMA_t = 0.1 * x_t + 0.9 * EMA_{t-1}
-----------------------------------------------------------------*/
recursive_ema (level4_cpc, level4_title, filing_year, filings, ema, rn) AS (
    -- seed (first year for each group)
    SELECT  level4_cpc,
            level4_title,
            filing_year,
            filings,
            filings        AS ema,
            rn
    FROM    ordered
    WHERE   rn = 1

    UNION ALL

    -- recursive step
    SELECT  o.level4_cpc,
            o.level4_title,
            o.filing_year,
            o.filings,
            0.1 * o.filings + 0.9 * r.ema  AS ema,
            o.rn
    FROM    recursive_ema r
    JOIN    ordered      o
          ON o.level4_cpc = r.level4_cpc
         AND o.rn        = r.rn + 1
),

/*-------------------------------------------------------------------- 6 */
best_year AS (
    SELECT  level4_title       AS "CPC_TITLE",
            level4_cpc         AS "CPC_GROUP",
            filing_year        AS "YEAR_WITH_HIGHEST_EMA",
            ema,
            ROW_NUMBER() OVER (PARTITION BY level4_cpc
                               ORDER BY ema DESC NULLS LAST, filing_year) AS rnk
    FROM    recursive_ema
)

SELECT  "CPC_TITLE",
        "CPC_GROUP",
        "YEAR_WITH_HIGHEST_EMA"
FROM    best_year
WHERE   rnk = 1
ORDER BY "CPC_GROUP";