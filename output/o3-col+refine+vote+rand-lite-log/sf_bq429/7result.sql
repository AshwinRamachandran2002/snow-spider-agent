/*  Top 5 states by average ZIP-code-level income gain (2015→2018) 
    together with their average number of vulnerable employees (2017)   */

WITH income_change AS (          -- 2015 vs 2018 median-income change per ZIP
    SELECT
        a."geo_id",
        SUBSTR(a."geo_id",1,2)                AS "state_code",
        (b."median_income" - a."median_income")::FLOAT  AS "income_diff"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL      AND b."median_income" IS NOT NULL
      AND a."median_income" <> -666666666    AND b."median_income" <> -666666666
), 

vulnerability AS (               -- weighted vulnerable employment per ZIP (2017)
    SELECT
        "geo_id",
        SUBSTR("geo_id",1,2) AS "state_code",
        (
            0.38423645320197042 * COALESCE("employed_wholesale_trade",0) +
            0.48071410777129553 * COALESCE("employed_construction",0) +
            0.89455676291236841 * COALESCE("employed_arts_entertainment_recreation_accommodation_food",0) +
            0.31315240083507306 * COALESCE("employed_information",0) +
            0.51                  * COALESCE("employed_retail_trade",0)
        )::FLOAT  AS "vulnerable_employees_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
)

SELECT
    ic."state_code",
    AVG(ic."income_diff")            AS "avg_income_diff_2015_2018",
    AVG(v."vulnerable_employees_2017") AS "avg_vulnerable_employees_2017"
FROM income_change ic
JOIN vulnerability  v
  ON ic."geo_id" = v."geo_id"
GROUP BY ic."state_code"
ORDER BY "avg_income_diff_2015_2018" DESC NULLS LAST
LIMIT 5;