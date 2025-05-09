WITH income_diff AS (
    SELECT
        z2015."geo_id" AS "zip_code",
        z2015."median_income" AS "median_income_2015",
        z2018."median_income" AS "median_income_2018",
        (z2018."median_income" - z2015."median_income") AS "income_difference"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z2015
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z2018
        ON z2015."geo_id" = z2018."geo_id"
    WHERE z2015."median_income" IS NOT NULL
        AND z2018."median_income" IS NOT NULL
),
vulnerable_zipcodes AS (
    SELECT
        i."zip_code",
        i."income_difference",
        e."employed_manufacturing",
        e."employed_wholesale_trade"
    FROM income_diff i
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR e
        ON i."zip_code" = e."geo_id"
    WHERE i."income_difference" < 0
        AND (e."employed_manufacturing" IS NOT NULL OR e."employed_wholesale_trade" IS NOT NULL)
),
vulnerable_workers AS (
    SELECT
        gz."state_fips_code",
        SUM(vz."employed_manufacturing" * 0.41) AS "Manufacturing_Vulnerable_Workers",
        SUM(vz."employed_wholesale_trade" * 0.38) AS "Wholesale_Vulnerable_Workers"
    FROM vulnerable_zipcodes vz
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES gz
        ON vz."zip_code" = gz."zip_code"
    GROUP BY gz."state_fips_code"
),
state_totals AS (
    SELECT
        sf."state" AS "State",
        ROUND(COALESCE(SUM(vw."Wholesale_Vulnerable_Workers"), 0), 4) AS "Wholesale_Vulnerable_Workers",
        ROUND(COALESCE(SUM(vw."Manufacturing_Vulnerable_Workers"), 0), 4) AS "Manufacturing_Vulnerable_Workers",
        ROUND(COALESCE(SUM(vw."Wholesale_Vulnerable_Workers"), 0) + COALESCE(SUM(vw."Manufacturing_Vulnerable_Workers"), 0), 4) AS "Total_Vulnerable_Workers"
    FROM vulnerable_workers vw
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
        ON sf."fips" = TO_NUMBER(vw."state_fips_code")
    GROUP BY sf."state"
)
SELECT
    "State",
    "Wholesale_Vulnerable_Workers",
    "Manufacturing_Vulnerable_Workers",
    "Total_Vulnerable_Workers"
FROM state_totals
ORDER BY "Total_Vulnerable_Workers" DESC NULLS LAST;