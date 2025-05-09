WITH zip_codes AS (
    SELECT "zip_code", "zip_code_geom"
    FROM FDA.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "state_code" = 'CO'
),
block_groups AS (
    SELECT "geo_id", "blockgroup_geom", "area_land_meters"
    FROM FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL
    WHERE "state_name" = 'Colorado'
),
banks AS (
    SELECT "zip_code", COUNT(*) AS bank_locations
    FROM FDA.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'CO'
    GROUP BY "zip_code"
),
zip_blockgroup_overlap AS (
    SELECT
        z."zip_code",
        b."geo_id" AS block_group_id,
        b."area_land_meters" AS blockgroup_area,
        ST_AREA(ST_INTERSECTION(
            ST_GEOGFROMWKB(z."zip_code_geom"),
            ST_GEOGFROMWKB(b."blockgroup_geom")
        )) AS intersection_area
    FROM zip_codes z
    JOIN block_groups b
        ON ST_INTERSECTS(
            ST_GEOGFROMWKB(z."zip_code_geom"),
            ST_GEOGFROMWKB(b."blockgroup_geom")
        )
),
overlap_ratios AS (
    SELECT
        o."zip_code",
        o.block_group_id,
        o.intersection_area,
        o.blockgroup_area,
        o.intersection_area / o.blockgroup_area AS overlap_ratio
    FROM zip_blockgroup_overlap o
    WHERE o.intersection_area IS NOT NULL AND o.blockgroup_area > 0
),
adjusted_block_group_count AS (
    SELECT
        "zip_code",
        SUM(overlap_ratio) AS adjusted_block_group_count
    FROM overlap_ratios
    GROUP BY "zip_code"
),
zip_code_concentration AS (
    SELECT
        b."zip_code",
        ROUND(b.bank_locations / a.adjusted_block_group_count, 4) AS bank_locations_per_block_group
    FROM adjusted_block_group_count a
    JOIN banks b ON a."zip_code" = b."zip_code"
    WHERE a.adjusted_block_group_count > 0
)
SELECT "zip_code", bank_locations_per_block_group
FROM zip_code_concentration
ORDER BY bank_locations_per_block_group DESC NULLS LAST
LIMIT 1;