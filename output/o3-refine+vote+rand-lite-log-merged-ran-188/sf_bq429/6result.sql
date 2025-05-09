/*  Top-5 states by greatest average ZIP-level change in median income (2018-2015)
    together with the corresponding average number of “vulnerable” employees
    (weighted employment in 2017 five-year ZIP estimates).                              */

WITH income_diff AS (
    /* average change in median income per state (ZIP codes, 2015 vs 2018) */
    SELECT
        SUBSTR(a."geo_id", 1, 2)                                   AS "state_code",
        AVG(b."median_income" - a."median_income")                 AS "avg_income_diff_18_15"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR" a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR" b
         ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
    GROUP BY SUBSTR(a."geo_id", 1, 2)
),
vulnerable_emp AS (
    /* average weighted vulnerable employment per state (ZIP codes, 2017) */
    SELECT
        SUBSTR(z."geo_id", 1, 2)                                   AS "state_code",
        AVG(
              z."employed_wholesale_trade"  * 0.38423645320197042
            + z."employed_construction"     * 0.48071410777129553
            + z."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841
            + z."employed_information"      * 0.31315240083507306
            + z."employed_retail_trade"     * 0.51
        )                                                          AS "avg_vulnerable_emp_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z
    GROUP BY SUBSTR(z."geo_id", 1, 2)
)

SELECT
    d."state_code",
    d."avg_income_diff_18_15",
    v."avg_vulnerable_emp_2017"
FROM income_diff d
JOIN vulnerable_emp v
  ON d."state_code" = v."state_code"
ORDER BY d."avg_income_diff_18_15" DESC NULLS LAST
LIMIT 5;