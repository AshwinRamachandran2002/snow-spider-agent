/* Compare 1998-2017 growth: Allegheny County wages vs. CPI-U “All items” */

WITH wages AS (              -- Allegheny County, PA (FIPS 42003)
    SELECT 1998 AS yr,
           "avg_wkly_wage_10_total_all_industries" AS val
    FROM   BLS.BLS_QCEW._1998_Q4
    WHERE  "geoid" = '42003'
    UNION ALL
    SELECT 2017 AS yr,
           "avg_wkly_wage_10_total_all_industries" AS val
    FROM   BLS.BLS_QCEW._2017_Q4
    WHERE  "geoid" = '42003'
),
cpi AS (                -- CPI-U, U.S. city average, All items, annual (M13)
    SELECT  "year" AS yr,
            "value" AS val
    FROM    BLS.BLS.C_CPI_U
    WHERE   "area_name" = 'U.S. city average'
      AND   "item_name" = 'All items'
      AND   "period"    = 'M13'
      AND   "year"      IN (1998, 2017)
),
w AS (                  -- pivot wages
    SELECT MAX(CASE WHEN yr = 1998 THEN val END) AS w1998,
           MAX(CASE WHEN yr = 2017 THEN val END) AS w2017
    FROM   wages
),
c AS (                  -- pivot CPI
    SELECT MAX(CASE WHEN yr = 1998 THEN val END) AS c1998,
           MAX(CASE WHEN yr = 2017 THEN val END) AS c2017
    FROM   cpi
)
SELECT
    ROUND( (w.w2017 - w.w1998) / w.w1998 * 100 , 2) AS wage_growth_percent,
    ROUND( (c.c2017 - c.c1998) / c.c1998 * 100 , 2) AS cpi_growth_percent
FROM   w
CROSS  JOIN c;