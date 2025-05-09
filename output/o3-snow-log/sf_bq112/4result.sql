/*  Between 1998 and 2017, compare Allegheny County (PA – FIPS 42003)
    average-weekly wages (all industries) with the U.S.-city-average CPI
    for “All items”.  Return the percentage growth for each series
    (rounded to two decimals) and indicate whether wages kept pace
    with inflation.                                                   */

WITH wage_quarters AS (          -- pull the four QCEW quarters for each year
    SELECT 1998 AS "year", "avg_wkly_wage_10_total_all_industries" AS "wage"
      FROM BLS.BLS_QCEW."_1998_Q1"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_1998_Q2"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_1998_Q3"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 1998, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_1998_Q4"  WHERE "geoid" = '42003'

    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_2017_Q1"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_2017_Q2"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_2017_Q3"  WHERE "geoid" = '42003'
    UNION ALL
    SELECT 2017, "avg_wkly_wage_10_total_all_industries"
      FROM BLS.BLS_QCEW."_2017_Q4"  WHERE "geoid" = '42003'
),
wage_annual AS (                 -- average the four quarters
    SELECT "year",
           AVG("wage") AS "avg_wage"
    FROM   wage_quarters
    GROUP  BY "year"
),
cpi_months AS (                  -- monthly CPI values for the two years
    SELECT "year", "value"
    FROM   BLS.BLS."C_CPI_U"
    WHERE  "area_code" = '0'            -- U.S.-city-average
      AND  "item_code" = 'SA0'          -- All items
      AND  "year" IN (1998, 2017)
),
cpi_annual AS (                  -- annual average CPI
    SELECT "year",
           AVG("value") AS "avg_cpi"
    FROM   cpi_months
    GROUP  BY "year"
),
numbers AS (                     -- collect the four scalar values
    SELECT
        (SELECT "avg_wage" FROM wage_annual WHERE "year" = 1998) AS "wage_1998",
        (SELECT "avg_wage" FROM wage_annual WHERE "year" = 2017) AS "wage_2017",
        (SELECT "avg_cpi"  FROM cpi_annual  WHERE "year" = 1998) AS "cpi_1998",
        (SELECT "avg_cpi"  FROM cpi_annual  WHERE "year" = 2017) AS "cpi_2017"
)
SELECT
    ROUND( ( "wage_2017" / "wage_1998" - 1 ) * 100 , 2 ) AS "wage_pct_growth",
    ROUND( ( "cpi_2017"  / "cpi_1998"  - 1 ) * 100 , 2 ) AS "cpi_pct_growth",
    CASE
        WHEN ( "wage_2017" / "wage_1998" ) >= ( "cpi_2017" / "cpi_1998" )
             THEN 'Yes'
             ELSE 'No'
    END AS "wages_kept_pace_with_inflation"
FROM numbers;