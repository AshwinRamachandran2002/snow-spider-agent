SELECT
    final_results."zip_code",
    ROUND(SUM(final_results."bank_locations_in_blockgroup") / COUNT(DISTINCT final_results."geo_id"), 4) AS "bank_locations_per_block_group"
FROM (
    SELECT
        bg."geo_id",
        z."zip_code",
        (
            bl."bank_locations" * (
                ST_AREA(ST_INTERSECTION(TO_GEOGRAPHY(z."zip_code_geom"), TO_GEOGRAPHY(bg."blockgroup_geom")))
                / ST_AREA(TO_GEOGRAPHY(bg."blockgroup_geom"))
            )
        ) AS "bank_locations_in_blockgroup"
    FROM "FDA"."GEO_US_BOUNDARIES"."ZIP_CODES" z
    JOIN "FDA"."GEO_CENSUS_BLOCKGROUPS"."US_BLOCKGROUPS_NATIONAL" bg
        ON ST_INTERSECTS(TO_GEOGRAPHY(z."zip_code_geom"), TO_GEOGRAPHY(bg."blockgroup_geom"))
    JOIN (
        SELECT "zip_code", COUNT(DISTINCT "branch_fdic_uninum") AS "bank_locations"
        FROM "FDA"."FDIC_BANKS"."LOCATIONS"
        WHERE "state" = 'CO'
        GROUP BY "zip_code"
    ) bl ON z."zip_code" = bl."zip_code"
    WHERE z."state_code" = 'CO' AND bg."state_fips_code" = '08'
) final_results
GROUP BY final_results."zip_code"
ORDER BY "bank_locations_per_block_group" DESC NULLS LAST
LIMIT 1;