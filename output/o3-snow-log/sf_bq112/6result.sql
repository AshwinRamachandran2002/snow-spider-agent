/*  Compare growth in average annual weekly wages (Allegheny County PA, GEOID 42003)
    with growth in CPI-U (all items, U.S. city average) between 1998 and 2017           */

WITH wage AS (  -----------------------------------------------------------------
    /*  Annual-average weekly wages (average of the four quarters)  */
    SELECT 1998 AS yr,
           AVG("avg_wkly_wage_10_total_all_industries") AS wage_avg
    FROM  (
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._1998_Q1 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._1998_Q2 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._1998_Q3 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._1998_Q4 WHERE "geoid" = '42003'
    )
    UNION ALL
    SELECT 2017,
           AVG("avg_wkly_wage_10_total_all_industries")
    FROM  (
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._2017_Q1 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._2017_Q2 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._2017_Q3 WHERE "geoid" = '42003'
           UNION ALL
           SELECT "avg_wkly_wage_10_total_all_industries" FROM BLS.BLS_QCEW._2017_Q4 WHERE "geoid" = '42003'
    )
), -------------------------------------------------------------------------------
cpi AS (      /*  Annual-average CPI-U (period M13)  */
    SELECT "year" AS yr,
           "value" AS cpi_val
    FROM   BLS.BLS.C_CPI_U
    WHERE  "item_code" = 'SA0'      -- all items
      AND  "area_code" = '0'        -- U.S. city average
      AND  "period"    = 'M13'
      AND  "year" IN (1998, 2017)
), -------------------------------------------------------------------------------
combined AS (
    SELECT
        (SELECT wage_avg FROM wage WHERE yr = 1998) AS wage_1998,
        (SELECT wage_avg FROM wage WHERE yr = 2017) AS wage_2017,
        (SELECT cpi_val  FROM cpi  WHERE yr = 1998) AS cpi_1998,
        (SELECT cpi_val  FROM cpi  WHERE yr = 2017) AS cpi_2017
)
SELECT
    ROUND( (wage_2017 - wage_1998) / wage_1998 * 100 , 2 ) AS wage_growth_pct,
    ROUND( (cpi_2017  - cpi_1998) / cpi_1998 * 100 , 2 )   AS cpi_growth_pct,
    CASE
        WHEN (wage_2017 - wage_1998) / wage_1998
           >= (cpi_2017  - cpi_1998) / cpi_1998
        THEN 'Yes'
        ELSE 'No'
    END AS wages_kept_pace
FROM combined;