WITH zip_bank_counts AS (
    SELECT "zip_code", COUNT(*) AS "location_count"
    FROM FEC.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'UT'
    GROUP BY "zip_code"
),
min_location_count AS (
    SELECT MIN("location_count") AS min_count
    FROM zip_bank_counts
),
zip_with_min_count AS (
    SELECT zbc."zip_code"
    FROM zip_bank_counts zbc
    JOIN min_location_count mlc
      ON zbc."location_count" = mlc.min_count
    ORDER BY zbc."zip_code"
    LIMIT 1
),
employment_data AS (
    SELECT acs."geo_id" AS "zip_code", acs."employed_pop", acs."pop_16_over"
    FROM FEC.CENSUS_BUREAU_ACS.ZIP_CODES_2016_5YR acs
    JOIN zip_with_min_count zwmc
      ON acs."geo_id" = zwmc."zip_code"
)
SELECT ROUND((ed."employed_pop" / NULLIF(ed."pop_16_over", 0)) * 100, 4) AS "employment_rate"
FROM employment_data ed;