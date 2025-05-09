/*--------------------------------------------------------------------
  Colorado ZIP code with the highest concentration of bank locations
  per census block-group, computed from ZIP-to-block-group overlap
--------------------------------------------------------------------*/
WITH
/* 1. Colorado ZIP-code geometries */
"zip_geom_co" AS (
    SELECT
        "zip_code",
        TO_GEOGRAPHY("zip_code_geom")              AS "zip_geog"
    FROM FDA.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "state_code" = 'CO'
),

/* 2. Colorado census block-group geometries (FIPS state code 08) */
"bg_geom_co" AS (
    SELECT
        "geo_id",
        TO_GEOGRAPHY("blockgroup_geom")            AS "bg_geog",
        ("area_land_meters" + "area_water_meters") AS "bg_area_m2"
    FROM FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL
    WHERE LEFT("geo_id", 2) = '08'     -- Colorado
),

/* 3. Spatial intersection between ZIPs and block-groups */
"zip_bg_overlap" AS (
    SELECT
        z."zip_code",
        b."geo_id",
        ST_AREA( ST_INTERSECTION(z."zip_geog", b."bg_geog") )  AS "intersect_area_m2",
        b."bg_area_m2"
    FROM "zip_geom_co" z
    JOIN "bg_geom_co"  b
      ON ST_INTERSECTS(z."zip_geog", b."bg_geog")
    WHERE ST_AREA( ST_INTERSECTION(z."zip_geog", b."bg_geog") ) > 0
),

/* 4. Overlap ratio of each block-group portion that lies in a ZIP */
"zip_bg_ratio" AS (
    SELECT
        "zip_code",
        "geo_id",
        "intersect_area_m2",
        "bg_area_m2",
        "intersect_area_m2" / NULLIF("bg_area_m2", 0) AS "overlap_ratio"
    FROM "zip_bg_overlap"
),

/* 5. Number of bank locations recorded for each Colorado ZIP */
"zip_bank_counts" AS (
    SELECT
        "zip_code",
        COUNT(*) AS "bank_cnt"
    FROM FDA.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'CO'
    GROUP BY "zip_code"
),

/* 6. Distribute ZIP-level bank counts to block-groups by overlap ratio */
"banks_assigned_to_bg" AS (
    SELECT
        r."geo_id",
        r."zip_code",
        r."overlap_ratio" * COALESCE(b."bank_cnt", 0) AS "banks_in_bg"
    FROM "zip_bg_ratio" r
    LEFT JOIN "zip_bank_counts" b
           ON r."zip_code" = b."zip_code"
),

/* 7. For each ZIP: total assigned banks and number of block-groups covered */
"zip_level_stats" AS (
    SELECT
        "zip_code",
        SUM("banks_in_bg")                AS "total_banks",
        COUNT(DISTINCT "geo_id")          AS "bg_cnt"
    FROM "banks_assigned_to_bg"
    GROUP BY "zip_code"
),

/* 8. Concentration = banks per block-group */
"zip_concentration" AS (
    SELECT
        "zip_code",
        "total_banks" / NULLIF("bg_cnt", 0) AS "banks_per_bg"
    FROM "zip_level_stats"
)

/* 9. Return the ZIP with the highest concentration */
SELECT
    "zip_code"
FROM "zip_concentration"
ORDER BY "banks_per_bg" DESC NULLS LAST
LIMIT 1;