WITH zip_income_diff AS (   -- 1. Δ Median-income per ZIP (2018 – 2015)
    SELECT
        t15."geo_id",
        s."state",
        s."postal_code",
        TO_NUMBER(t15."median_income")  AS median_2015,
        TO_NUMBER(t18."median_income")  AS median_2018,
        (TO_NUMBER(t18."median_income") - TO_NUMBER(t15."median_income")) AS median_diff
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" t15
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" t18
          ON t15."geo_id" = t18."geo_id"
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS"               s
          ON s."fips" = TO_NUMBER(SUBSTR(t15."geo_id",1,2))
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
),
state_income_change AS (    -- 2. Average Δ Median-income by state
    SELECT
        "state",
        "postal_code",
        AVG(median_diff) AS avg_median_diff
    FROM zip_income_diff
    GROUP BY "state","postal_code"
),
zip_vulnerable_emp AS (     -- 3. Vulnerable-employee count per ZIP (2017)
    SELECT
        z17."geo_id",
        s."state",
        s."postal_code",
        ( 0.38423645320197042 * COALESCE(z17."employed_wholesale_trade",0)
        + 0.48071410777129553 * COALESCE(z17."employed_construction",0)
        + 0.89455676291236841 * COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)
        + 0.31315240083507306 * COALESCE(z17."employed_information",0)
        + 0.51000000000000000 * COALESCE(z17."employed_retail_trade",0)
        ) AS vulnerable_emp_2017
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"  z17
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS"                  s
          ON s."fips" = TO_NUMBER(SUBSTR(z17."geo_id",1,2))
),
state_vulnerable_emp AS (   -- 4. Average vulnerable employees by state
    SELECT
        "state",
        "postal_code",
        AVG(vulnerable_emp_2017) AS avg_vulnerable_emp_2017
    FROM zip_vulnerable_emp
    GROUP BY "state","postal_code"
)
-- 5. Combine the two state-level measures and return the top 5
SELECT
    ic."state",
    ic."postal_code",
    ic.avg_median_diff,
    ve.avg_vulnerable_emp_2017
FROM state_income_change  ic
JOIN state_vulnerable_emp ve
  ON ic."state" = ve."state"
ORDER BY ic.avg_median_diff DESC NULLS LAST
LIMIT 5;