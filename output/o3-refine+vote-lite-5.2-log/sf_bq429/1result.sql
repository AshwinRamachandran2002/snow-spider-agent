/*  Top‑5 states with largest ZIP‑level increase in median income
    (2015 → 2018) together with average 2017 vulnerable employment            */
WITH income_diff AS (   -- 2018 minus 2015 median income for every ZIP code
    SELECT
        gz."state_code",
        z18."geo_id"                                  AS zip,
        z18."median_income" - z15."median_income"     AS diff
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  z18
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  z15
           ON z18."geo_id" = z15."geo_id"
    JOIN  CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           gz
           ON gz."zip_code" = z18."geo_id"
    WHERE z18."median_income" IS NOT NULL
      AND z15."median_income" IS NOT NULL
),
vulnerable AS (         -- 2017 weighted vulnerable employees per ZIP
    SELECT
        gz."state_code",
        z17."geo_id"                                  AS zip,
        (   z17."employed_wholesale_trade"   * 0.38423645320197042
          + z17."employed_construction"      * 0.48071410777129553
          + z17."employed_arts_entertainment_recreation_accommodation_food"
                                             * 0.89455676291236841
          + z17."employed_information"       * 0.31315240083507306
          + z17."employed_retail_trade"      * 0.51000000000000000
        ) AS vulnerable_emp
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  z17
    JOIN  CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."ZIP_CODES"           gz
           ON gz."zip_code" = z17."geo_id"
),
state_aggregates AS (   -- averages by state
    SELECT
        i."state_code",
        AVG(i.diff)            AS avg_income_diff,
        AVG(v.vulnerable_emp)  AS avg_vulnerable_emp
    FROM income_diff i
    LEFT JOIN vulnerable v
           ON v.zip = i.zip
    GROUP BY i."state_code"
)
SELECT
    s."state_name"                                          AS state,
    ROUND(sa.avg_income_diff , 2)                           AS avg_median_income_diff_2015_2018,
    ROUND(sa.avg_vulnerable_emp, 2)                         AS avg_vulnerable_employees_2017
FROM  state_aggregates sa
JOIN  CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES."STATES" s
      ON s."state" = sa."state_code"
ORDER BY sa.avg_income_diff DESC NULLS LAST,
         s."state_name"
LIMIT 5;