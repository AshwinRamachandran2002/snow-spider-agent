/*  Top-5 states with the largest average ZIP-level change in median household
    income (2015 → 2018) together with the corresponding average number of
    “vulnerable” employees (2017)                                           */

WITH income_diff AS (           -- 2015 → 2018 median-income change per ZIP
    SELECT
        z17."geo_id",
        ( z18."median_income"
        - TO_NUMBER(z15."median_income") )     AS "inc_diff"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
          ON z17."geo_id" = z15."geo_id"
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
          ON z17."geo_id" = z18."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
),
vulnerable_emp AS (             -- 2017 weighted vulnerable-employee count
    SELECT
        z."geo_id",
          0.38423645320197042 * COALESCE(z."employed_wholesale_trade",0)  +
          0.48071410777129553 * COALESCE(z."employed_construction",0)     +
          0.89455676291236841 * COALESCE(
                  z."employed_arts_entertainment_recreation_accommodation_food",0) +
          0.31315240083507306 * COALESCE(z."employed_information",0)      +
          0.51000000000000000 * COALESCE(z."employed_retail_trade",0)     AS "vulnerable_emp"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR" z
),
combined AS (                   -- bring income & vulnerability together
    SELECT
        i."geo_id",
        i."inc_diff",
        v."vulnerable_emp"
    FROM  income_diff     i
    JOIN  vulnerable_emp  v  USING ("geo_id")
)

SELECT
    s."postal_code"                             AS "state",
    AVG(c."inc_diff")        AS "avg_income_diff_2015_2018",
    AVG(c."vulnerable_emp")  AS "avg_vulnerable_employees_2017"
FROM  combined                                      c
JOIN  CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"    s
      ON TO_NUMBER(SUBSTR(c."geo_id",1,2)) = s."fips"
GROUP BY s."postal_code"
ORDER BY "avg_income_diff_2015_2018" DESC NULLS LAST
LIMIT 5;