WITH income_delta AS (
    SELECT
        a."geo_id"                           AS "zip",
        bnd."state_code"                     AS "state",
        (b."median_income" - a."median_income")::FLOAT AS "income_diff"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR"  a
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR"  b
          ON a."geo_id" = b."geo_id"
    JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES"           bnd
          ON a."geo_id" = bnd."zip_code"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
),
vulnerable AS (
    SELECT
        v."geo_id" AS "zip",
        /* weighted vulnerable‑employee count */
        ( COALESCE(v."employed_wholesale_trade",0)      * 0.38423645320197042
        + COALESCE(v."employed_construction",0)         * 0.48071410777129553
        + COALESCE(v."employed_arts_entertainment_recreation_accommodation_food",0)
                                                     * 0.89455676291236841
        + COALESCE(v."employed_information",0)          * 0.31315240083507306
        + COALESCE(v."employed_retail_trade",0)         * 0.51000000000000000
        ) AS "vuln_emp_2017"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" v
),
state_summary AS (
    SELECT
        i."state",
        AVG(i."income_diff")          AS "avg_diff_median_income_2015_2018",
        AVG(v."vuln_emp_2017")        AS "avg_vulnerable_employees_2017"
    FROM income_delta i
    JOIN vulnerable v
      ON i."zip" = v."zip"
    GROUP BY i."state"
)
SELECT
    s."state"                                                  AS state,
    ROUND(s."avg_diff_median_income_2015_2018", 4)             AS avg_diff_median_income_2015_2018,
    ROUND(s."avg_vulnerable_employees_2017", 4)                AS avg_vulnerable_employees_2017
FROM state_summary s
ORDER BY s."avg_diff_median_income_2015_2018" DESC NULLS LAST, s."state"
LIMIT 5;