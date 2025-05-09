WITH min_locations_zipcodes AS (
    SELECT "zip_code"
    FROM (
        SELECT "zip_code", COUNT(*) AS "num_locations"
        FROM "FEC"."FDIC_BANKS"."LOCATIONS"
        WHERE "state" = 'UT'
        GROUP BY "zip_code"
    ) t
    WHERE t."num_locations" = (
        SELECT MIN("num_locations")
        FROM (
            SELECT COUNT(*) AS "num_locations"
            FROM "FEC"."FDIC_BANKS"."LOCATIONS"
            WHERE "state" = 'UT'
            GROUP BY "zip_code"
        ) s
    )
),
zip_employment AS (
    SELECT RIGHT(z."geo_id", 5) AS "zip_code", z."employed_pop", z."pop_16_over"
    FROM "FEC"."CENSUS_BUREAU_ACS"."ZCTA5_2017_5YR" z
    WHERE RIGHT(z."geo_id",5) IN (
        SELECT "zip_code" FROM min_locations_zipcodes
    )
    AND z."pop_16_over" IS NOT NULL AND z."pop_16_over" > 0
),
zip_employment_rate AS (
    SELECT "zip_code", ("employed_pop" / "pop_16_over") * 100 AS "Employment_rate"
    FROM zip_employment
)
SELECT ROUND("Employment_rate", 4) AS "Employment_rate"
FROM zip_employment_rate
ORDER BY "Employment_rate" ASC
LIMIT 1;