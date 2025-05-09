/* --------------------------------------------------------------
   CPC level-5 technology areas – peak exponential moving average
   --------------------------------------------------------------*/
WITH RECURSIVE
/*1)  Extract first-listed CPC code and filing year (YYYY)           */
pubs AS (
    SELECT
        SUBSTR(f.value:"code"::STRING , 1 , 4)        AS cpc_group,   -- level-5 symbol
        FLOOR(p."filing_date" / 10000)                AS filing_year
    FROM PATENTS.PATENTS.PUBLICATIONS p ,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE f.index = 0                                 -- first CPC only
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" >= 10000                    -- exclude 0 / junk
      AND COALESCE(p."application_number", '') <> ''
),
/*2)  Year-by-year filing counts for every CPC group                */
year_counts AS (
    SELECT
        cpc_group,
        filing_year                                  AS yr,
        COUNT(*)                                     AS filings_cnt
    FROM pubs
    GROUP BY cpc_group , yr
),
/*3)  Row numbering within each group (needed for recursion)        */
ordered AS (
    SELECT
        cpc_group,
        yr,
        filings_cnt,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY yr) AS rn
    FROM year_counts
),
/*4)  Recursive EMA calculation with α = 0.2                        */
ema_cte (cpc_group, yr, filings_cnt, ema_val, rn) AS (
    /* anchor rows: first year of each group                         */
    SELECT
        cpc_group,
        yr,
        filings_cnt::FLOAT,
        filings_cnt::FLOAT                       AS ema_val,
        rn
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* recursive step                                                */
    SELECT
        o.cpc_group,
        o.yr,
        o.filings_cnt::FLOAT,
        0.2 * o.filings_cnt + 0.8 * e.ema_val     AS ema_val,
        o.rn
    FROM ema_cte  e
    JOIN ordered o
      ON o.cpc_group = e.cpc_group
     AND o.rn       = e.rn + 1
),
/*5)  Locate peak EMA and its year for each CPC group               */
peak_per_group AS (
    SELECT
        cpc_group,
        yr                      AS best_year,
        ema_val                 AS peak_ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY ema_val DESC NULLS LAST , yr) AS rk
    FROM ema_cte
)
/*6)  Bring in CPC full title (level-5) and present results         */
SELECT
    pg.cpc_group                           AS "CPC_Group",
    d."titleFull"                          AS "CPC_Full_Title",
    pg.best_year                           AS "Best_Year",
    ROUND(pg.peak_ema, 4)                  AS "Peak_EMA_Filings"
FROM peak_per_group pg
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = pg.cpc_group
WHERE d."level" = 5
  AND pg.rk = 1                            -- keep only the peak row
ORDER BY pg.peak_ema DESC NULLS LAST;