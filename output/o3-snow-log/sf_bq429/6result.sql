/*  Top 5 states by average ZIP-level median-income increase (2015→2018)
    and their corresponding average number of vulnerable employees (2017)
    across wholesale trade, construction, arts & entertainment, information,
    and retail industries. */

WITH income_deltas AS (
    SELECT
        sf."state",
        (z18."median_income"::FLOAT - z15."median_income"::FLOAT) AS "delta"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  z15
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  z18
          ON z15."geo_id" = z18."geo_id"
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf
          ON LPAD(sf."fips"::STRING, 2, '0') = SUBSTR(z15."geo_id", 1, 2)
    WHERE z15."median_income" IS NOT NULL
      AND z18."median_income" IS NOT NULL
),
state_income AS (
    SELECT
        "state",
        AVG("delta") AS "avg_income_diff_2015_2018"
    FROM income_deltas
    GROUP BY "state"
),
vuln_zip AS (
    SELECT
        sf."state",
        /* weighted vulnerable-employee count for each ZIP in 2017 */
        COALESCE(z."employed_wholesale_trade", 0) * 0.38423645320197042 +
        COALESCE(z."employed_construction",    0) * 0.48071410777129553 +
        COALESCE(z."employed_arts_entertainment_recreation_accommodation_food", 0)
                                                * 0.89455676291236841 +
        COALESCE(z."employed_information",      0) * 0.31315240083507306 +
        COALESCE(z."employed_retail_trade",     0) * 0.51               AS "vuln_emp"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" z
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf
          ON LPAD(sf."fips"::STRING, 2, '0') = SUBSTR(z."geo_id", 1, 2)
),
state_vuln AS (
    SELECT
        "state",
        AVG("vuln_emp") AS "avg_vulnerable_employees_2017"
    FROM vuln_zip
    GROUP BY "state"
)
SELECT
    i."state",
    i."avg_income_diff_2015_2018",
    v."avg_vulnerable_employees_2017"
FROM   state_income i
JOIN   state_vuln   v  ON i."state" = v."state"
ORDER  BY i."avg_income_diff_2015_2018" DESC NULLS LAST
LIMIT 5;