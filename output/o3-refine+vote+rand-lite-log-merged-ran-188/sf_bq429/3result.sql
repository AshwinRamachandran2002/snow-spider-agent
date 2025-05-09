/*  Top-5 states (two-digit state-FIPS ZIP prefix) with the largest
    average ZIP-level median-income change (2015→2018) and the
    corresponding 2017 average of “vulnerable” employees              */

WITH diff_zip AS (                   /* 2015 vs 2018 income change per ZIP */
    SELECT  a."geo_id"                           AS "zip",
            SUBSTR(a."geo_id", 1, 2)             AS "state_fips",
            CAST(b."median_income" AS DOUBLE) 
          - CAST(a."median_income" AS DOUBLE)    AS "income_diff"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  a
    JOIN   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  b
           ON a."geo_id" = b."geo_id"
    WHERE  a."median_income" IS NOT NULL
      AND  b."median_income" IS NOT NULL
), vuln_zip AS (                    /* weighted vulnerable employment 2017 */
    SELECT  c."geo_id"                          AS "zip",
            SUBSTR(c."geo_id", 1, 2)            AS "state_fips",
            0.38423645320197042 * c."employed_wholesale_trade" +
            0.48071410777129553 * c."employed_construction"   +
            0.89455676291236841 * c."employed_arts_entertainment_recreation_accommodation_food" +
            0.31315240083507306 * c."employed_information"    +
            0.51                 * c."employed_retail_trade"  AS "vulnerable_emp"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"  c
), state_metrics AS (               /* state-level averages */
    SELECT  d."state_fips",
            AVG(d."income_diff")     AS "avg_income_diff",
            AVG(v."vulnerable_emp")  AS "avg_vulnerable_emp"
    FROM    diff_zip d
    LEFT JOIN vuln_zip v
           ON d."zip" = v."zip"
    GROUP BY d."state_fips"
)
SELECT  "state_fips",
        "avg_income_diff",
        "avg_vulnerable_emp"
FROM    state_metrics
ORDER BY "avg_income_diff" DESC NULLS LAST
LIMIT 5;