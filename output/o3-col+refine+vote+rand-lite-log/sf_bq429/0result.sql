WITH income_change AS (
    /* 2015 ➜ 2018 ZIP-level median-income change */
    SELECT
        SUBSTR(a."geo_id",1,2) AS "state_fips",
        AVG( b."median_income" - a."median_income" )  AS "avg_zip_inc_diff_2015_2018"
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"  a
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2018_5YR"  b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
    GROUP BY SUBSTR(a."geo_id",1,2)
),
vulnerable_emp AS (
    /* 2017 average vulnerable-industry employment per ZIP, then averaged by state */
    SELECT
        SUBSTR("geo_id",1,2) AS "state_fips",
        AVG( ( COALESCE("employed_wholesale_trade",0) +
               COALESCE("employed_construction",0) +
               COALESCE("employed_arts_entertainment_recreation_accommodation_food",0) +
               COALESCE("employed_information",0) +
               COALESCE("employed_retail_trade",0) ) / 5.0
        ) AS "state_avg_vulnerable_emp_2017"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."ZIP_CODES_2017_5YR"
    GROUP BY SUBSTR("geo_id",1,2)
)
SELECT
    i."state_fips",
    i."avg_zip_inc_diff_2015_2018",
    v."state_avg_vulnerable_emp_2017"
FROM   income_change i
JOIN   vulnerable_emp v
       ON i."state_fips" = v."state_fips"
ORDER  BY i."avg_zip_inc_diff_2015_2018" DESC NULLS LAST
LIMIT  5;