WITH income_decreased_zips AS (
    SELECT
        LPAD(TRIM(t2015."geo_id"), 5, '0') AS "zip_code"
    FROM
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" AS t2015
    JOIN
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" AS t2018
        ON t2015."geo_id" = t2018."geo_id"
    WHERE
        t2015."median_income" IS NOT NULL
        AND t2018."median_income" IS NOT NULL
        AND (t2018."median_income" - t2015."median_income") < 0
),
employment_data AS (
    SELECT
        LPAD(TRIM(emp."geo_id"), 5, '0') AS "zip_code",
        ROUND(emp."employed_wholesale_trade" * 0.38, 4) AS "vulnerable_wholesale_trade_workers",
        ROUND(emp."employed_manufacturing" * 0.41, 4) AS "vulnerable_manufacturing_workers"
    FROM
        "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" AS emp
    WHERE
        emp."employed_wholesale_trade" IS NOT NULL
        AND emp."employed_manufacturing" IS NOT NULL
),
zip_state_mapping AS (
    SELECT
        LPAD(TRIM(zc."zip_code"), 5, '0') AS "zip_code",
        zc."state_name"
    FROM
        "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" AS zc
    WHERE
        zc."state_name" IS NOT NULL
)
SELECT
    zs."state_name",
    SUM(ed."vulnerable_wholesale_trade_workers") AS "vulnerable_wholesale_trade_workers",
    SUM(ed."vulnerable_manufacturing_workers") AS "vulnerable_manufacturing_workers",
    SUM(ed."vulnerable_wholesale_trade_workers" + ed."vulnerable_manufacturing_workers") AS "total_vulnerable_workers"
FROM
    income_decreased_zips AS id
JOIN
    employment_data AS ed ON id."zip_code" = ed."zip_code"
JOIN
    zip_state_mapping AS zs ON id."zip_code" = zs."zip_code"
GROUP BY
    zs."state_name"
ORDER BY
    "total_vulnerable_workers" DESC NULLS LAST;