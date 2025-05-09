WITH bank_counts AS (
    SELECT "zip_code", COUNT(*) AS "bank_count"
    FROM FEC.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'UT'
    GROUP BY "zip_code"
),
min_bank_count AS (
    SELECT MIN("bank_count") AS "min_bank_count"
    FROM bank_counts
),
min_zip_codes AS (
    SELECT bc."zip_code"
    FROM bank_counts bc
    JOIN min_bank_count mbc ON bc."bank_count" = mbc."min_bank_count"
),
acs_employment AS (
    SELECT "geo_id" AS "zip_code", "pop_16_over", "employed_pop"
    FROM FEC.CENSUS_BUREAU_ACS.ZCTA5_2017_5YR
)
SELECT mz."zip_code",
       ROUND((ae."employed_pop" / NULLIF(ae."pop_16_over", 0)) * 100, 4) AS "employment_rate"
FROM min_zip_codes mz
JOIN acs_employment ae ON mz."zip_code" = ae."zip_code"
LIMIT 1;