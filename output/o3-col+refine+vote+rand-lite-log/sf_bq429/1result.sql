WITH income_2015 AS (   -- average 2015 median-income per state (ZIP-level, 5-yr ACS)
    SELECT
        SUBSTR("geo_id", 1, 2)                 AS "state_fips",
        AVG(CAST("median_income" AS DOUBLE))   AS "avg_income_2015"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
    WHERE "median_income" IS NOT NULL
      AND "median_income" <> -666666666        -- drop sentinel for missing values
    GROUP BY "state_fips"
),
income_2018 AS (   -- average 2018 median-income per state (ZIP-level, 5-yr ACS)
    SELECT
        SUBSTR("geo_id", 1, 2)                 AS "state_fips",
        AVG(CAST("median_income" AS DOUBLE))   AS "avg_income_2018"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"
    WHERE "median_income" IS NOT NULL
      AND "median_income" <> -666666666
    GROUP BY "state_fips"
),
income_diff AS (   -- 2015→2018 average income change per state
    SELECT
        i18."state_fips",
        i18."avg_income_2018" - i15."avg_income_2015" AS "avg_income_diff"
    FROM income_2018 i18
    JOIN income_2015 i15
      ON i18."state_fips" = i15."state_fips"
),
vulnerable_emp_2017 AS (   -- average weighted vulnerable employment per state (ZIP-level, 5-yr ACS)
    SELECT
        SUBSTR("geo_id", 1, 2) AS "state_fips",
        AVG(
              COALESCE("employed_arts_entertainment_recreation_accommodation_food", 0) * 0.89455676291236841
            + COALESCE("employed_construction",                                  0) * 0.48071410777129553
            + COALESCE("employed_wholesale_trade",                               0) * 0.38423645320197042
            + COALESCE("employed_information",                                   0) * 0.31315240083507306
            + COALESCE("employed_retail_trade",                                  0) * 0.51
        ) AS "avg_vulnerable_emp_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
    GROUP BY "state_fips"
)
SELECT
    d."state_fips",
    d."avg_income_diff",
    v."avg_vulnerable_emp_2017"
FROM income_diff          d
JOIN vulnerable_emp_2017  v  ON d."state_fips" = v."state_fips"
ORDER BY d."avg_income_diff" DESC NULLS LAST
LIMIT 5;