WITH income_change AS (
    /* 2015 → 2018 average ZIP-level median-income difference per state */
    SELECT
        LEFT(a."geo_id", 2)                                       AS "state_fips",
        AVG(b."median_income" - a."median_income")                AS "avg_income_diff_2015_2018"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" a
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
    GROUP BY 1
),
vulnerable_workers AS (
    /* 2017 average number of vulnerable employees per state */
    SELECT
        LEFT("geo_id", 2)                                         AS "state_fips",
        AVG( 0.38423645320197042 * "employed_wholesale_trade"
            + 0.48071410777129553 * "employed_construction"
            + 0.89455676291236841 * "employed_arts_entertainment_recreation_accommodation_food"
            + 0.31315240083507306 * "employed_information"
            + 0.51                     * "employed_retail_trade" ) AS "avg_vulnerable_emp_2017"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR"
    GROUP BY 1
)

SELECT
    ic."state_fips",
    ic."avg_income_diff_2015_2018",
    vw."avg_vulnerable_emp_2017"
FROM   income_change      ic
JOIN   vulnerable_workers vw
       ON ic."state_fips" = vw."state_fips"
ORDER  BY ic."avg_income_diff_2015_2018" DESC NULLS LAST
LIMIT  5;