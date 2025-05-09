/*------------------------------------------------------------
   1)  Count FDIC-reported bank locations per Colorado ZIP code
-------------------------------------------------------------*/
WITH zip_bank_counts AS (
    SELECT 
        l."zip_code",
        COUNT(*)                       AS bank_locations
    FROM FDA.FDIC_BANKS."LOCATIONS" l
    WHERE l."state" = 'CO'
      AND l."zip_code" IS NOT NULL
    GROUP BY l."zip_code"
),

/*------------------------------------------------------------
   2)  Bring in Colorado ZIP-code geometries together with the
       bank-location counts calculated above
-------------------------------------------------------------*/
zip_geoms AS (
    SELECT
        z."zip_code",
        ST_GEOGFROMWKB(z."zip_code_geom")     AS zip_geom,
        b.bank_locations
    FROM FDA.GEO_US_BOUNDARIES."ZIP_CODES" z
    JOIN zip_bank_counts b
      ON z."zip_code" = b."zip_code"
    WHERE z."state_code" = 'CO'
),

/*------------------------------------------------------------
   3)  Load all census block-group geometries with their areas
-------------------------------------------------------------*/
bg_geoms AS (
    SELECT
        bg."geo_id",
        ST_GEOGFROMWKB(bg."blockgroup_geom")  AS bg_geom,
        ST_AREA( ST_GEOGFROMWKB(bg."blockgroup_geom") )  AS bg_area
    FROM FDA.GEO_CENSUS_BLOCKGROUPS."US_BLOCKGROUPS_NATIONAL" bg
),

/*------------------------------------------------------------
   4)  Calculate overlap ratio of every ZIP with every intersecting
       block group, distribute bank counts proportionally
-------------------------------------------------------------*/
distributed_banks AS (
    SELECT
        z."zip_code",
        bg."geo_id",
        /* overlap ratio = intersection area / block-group area */
        CASE 
            WHEN bg.bg_area > 0 THEN
                 ST_AREA( ST_INTERSECTION(z.zip_geom , bg.bg_geom) ) / bg.bg_area
            ELSE 0
        END                                             AS overlap_ratio,
        z.bank_locations,
        /* proportional share of bank locations in this block group */
        z.bank_locations *
        CASE 
            WHEN bg.bg_area > 0 THEN
                 ST_AREA( ST_INTERSECTION(z.zip_geom , bg.bg_geom) ) / bg.bg_area
            ELSE 0
        END                                             AS distributed_bank_locs
    FROM zip_geoms z
    JOIN bg_geoms bg
      ON ST_INTERSECTS(z.zip_geom , bg.bg_geom)
    WHERE ST_AREA( ST_INTERSECTION(z.zip_geom , bg.bg_geom) ) > 0
),

/*------------------------------------------------------------
   5)  For each ZIP, find the highest (maximum) number of bank
       locations assigned to any single block group – this is the
       “concentration” measure requested
-------------------------------------------------------------*/
zip_concentration AS (
    SELECT
        "zip_code",
        MAX(distributed_bank_locs)   AS max_bank_locs_per_blockgroup
    FROM distributed_banks
    GROUP BY "zip_code"
)

/*------------------------------------------------------------
   6)  Return the Colorado ZIP code with the greatest concentration
-------------------------------------------------------------*/
SELECT
    "zip_code"  AS colorado_zip_with_highest_concentration,
    max_bank_locs_per_blockgroup
FROM zip_concentration
ORDER BY max_bank_locs_per_blockgroup DESC NULLS LAST
LIMIT 1;