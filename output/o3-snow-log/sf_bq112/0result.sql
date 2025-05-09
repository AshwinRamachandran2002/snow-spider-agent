/* 1)  Pull 1998-Q4 and 2017-Q4 average weekly wages for “Total, all industries”
       in Allegheny County (GEOID 42003).                                     */
WITH wage AS (
    SELECT 1998 AS "year",
           "avg_wkly_wage_10_total_all_industries" AS wage
    FROM   BLS.BLS_QCEW._1998_Q4
    WHERE  "geoid" = '42003'

    UNION ALL

    SELECT 2017 AS "year",
           "avg_wkly_wage_10_total_all_industries" AS wage
    FROM   BLS.BLS_QCEW._2017_Q4
    WHERE  "geoid" = '42003'
),

/* 2)  Pull annual-average CPI-U (period M13) for “All items”
       — U.S. city average — for the same two years.                          */
cpi AS (
    SELECT 1998 AS "year", "value" AS cpi
    FROM   BLS.BLS.C_CPI_U
    WHERE  "area_name" = 'U.S. city average'
      AND  "item_name" = 'All items'
      AND  "period"    = 'M13'
      AND  "year"      = 1998

    UNION ALL

    SELECT 2017 AS "year", "value" AS cpi
    FROM   BLS.BLS.C_CPI_U
    WHERE  "area_name" = 'U.S. city average'
      AND  "item_name" = 'All items'
      AND  "period"    = 'M13'
      AND  "year"      = 2017
),

/* 3)  Compute percentage growth 1998 → 2017 for each series.                 */
growth AS (
    /* Wage growth */
    SELECT 'Average weekly wage – Allegheny County' AS metric,
           ROUND(
               (MAX(CASE WHEN "year" = 2017 THEN wage END) -
                MAX(CASE WHEN "year" = 1998 THEN wage END))
               / MAX(CASE WHEN "year" = 1998 THEN wage END) * 100
           , 2) AS percent_growth
    FROM   wage

    UNION ALL

    /* CPI growth */
    SELECT 'CPI-U (“All items”) – U.S. city average' AS metric,
           ROUND(
               (MAX(CASE WHEN "year" = 2017 THEN cpi END) -
                MAX(CASE WHEN "year" = 1998 THEN cpi END))
               / MAX(CASE WHEN "year" = 1998 THEN cpi END) * 100
           , 2) AS percent_growth
    FROM   cpi
)

/* 4)  Present the two growth rates.                                          */
SELECT *
FROM   growth;