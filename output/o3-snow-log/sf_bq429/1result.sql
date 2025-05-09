/*  Top-5 states (by greatest average ZIP-level change in median income, 2015→2018)
    together with the corresponding average number of “vulnerable employees” (2017)
    across the five specified industries.                                            */

WITH income_diff AS (          -- 1. 2018 vs 2015 median–income difference, per ZIP
    SELECT
        z15."geo_id",
        ( z18."median_income" - z15."median_income" )     AS "income_diff"
    FROM  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  z15
    JOIN  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  z18
          ON z15."geo_id" = z18."geo_id"
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
),
vulnerable AS (               -- 2. 2017 “weighted vulnerable-employees” metric
    SELECT
        z17."geo_id",
          ( 0.38423645320197042 * COALESCE(z17."employed_wholesale_trade" ,0)
          + 0.48071410777129553 * COALESCE(z17."employed_construction"    ,0)   -- natural resources & construction
          + 0.89455676291236841 * COALESCE(z17."employed_arts_entertainment_recreation_accommodation_food",0)
          + 0.31315240083507306 * COALESCE(z17."employed_information"     ,0)
          + 0.51                  * COALESCE(z17."employed_retail_trade"  ,0) ) AS "vulnerable_employees"
    FROM  "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"  z17
),
combined AS (                 -- 3. Merge the two ZIP-level measures & derive state FIPS
    SELECT
        i."geo_id",
        i."income_diff",
        v."vulnerable_employees",
        TO_NUMBER(LEFT(i."geo_id", 2))                  AS "state_fips"
    FROM  income_diff  i
    JOIN  vulnerable   v  ON i."geo_id" = v."geo_id"
),
state_agg AS (                -- 4. Aggregate to state level
    SELECT
        sf."state",
        sf."postal_code",
        AVG(c."income_diff")          AS "avg_income_diff",
        AVG(c."vulnerable_employees") AS "avg_vulnerable_employees"
    FROM  combined  c
    JOIN  "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS"  sf
          ON c."state_fips" = sf."fips"
    GROUP BY sf."state", sf."postal_code"
)

SELECT
    "state",
    "postal_code",
    "avg_income_diff",
    "avg_vulnerable_employees"
FROM   state_agg
ORDER  BY "avg_income_diff" DESC NULLS LAST
LIMIT  5;