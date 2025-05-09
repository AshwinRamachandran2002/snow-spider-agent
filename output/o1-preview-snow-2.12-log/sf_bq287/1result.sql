WITH bank_counts AS (
    SELECT "zip_code", COUNT(*) AS "bank_count"
    FROM "FEC"."FDIC_BANKS"."LOCATIONS"
    WHERE "state" = 'UT'
    GROUP BY "zip_code"
), min_bank_count AS (
    SELECT MIN("bank_count") AS "min_bank_count" FROM bank_counts
), min_zip_code AS (
    SELECT "zip_code"
    FROM bank_counts
    WHERE "bank_count" = (SELECT "min_bank_count" FROM min_bank_count)
    ORDER BY "zip_code" ASC
    LIMIT 1
), acs_data AS (
    SELECT RIGHT("geo_id", 5) AS "zip_code", "employed_pop", "pop_16_over"
    FROM "FEC"."CENSUS_BUREAU_ACS"."ZCTA5_2017_5YR"
)
SELECT m."zip_code", ROUND(("employed_pop" / NULLIF(a."pop_16_over", 0)) * 100, 4) AS "employment_rate"
FROM min_zip_code m
LEFT JOIN acs_data a ON m."zip_code" = a."zip_code";