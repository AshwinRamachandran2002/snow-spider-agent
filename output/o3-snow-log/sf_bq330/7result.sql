/*-------------------------------------------------------------
  Colorado ZIP code with the highest concentration of
  bank locations in a single census-block group
--------------------------------------------------------------*/
WITH co_zips AS (               -- 1. Colorado ZIP-code geometries
    SELECT
        z."zip_code"                           AS zip_code,
        TO_GEOGRAPHY(z."zip_code_geom")        AS zip_geom
    FROM FDA.GEO_US_BOUNDARIES."ZIP_CODES" z
    WHERE z."state_code" = 'CO'
),
co_bank_counts AS (             -- 2. Bank-location count per CO ZIP
    SELECT
        l."zip_code"                           AS zip_code,
        COUNT(*)                               AS bank_locations
    FROM FDA.FDIC_BANKS."LOCATIONS" l
    WHERE l."state" = 'CO'
    GROUP BY l."zip_code"
),
zip_block_overlap AS (          -- 3. ZIP ↔ block-group intersections
    SELECT
        z.zip_code,
        b."geo_id"                            AS geo_id,
        ST_AREA(
            ST_INTERSECTION(
                z.zip_geom,
                TO_GEOGRAPHY(b."blockgroup_geom")
            )
        )                                     AS intersect_area_m2,
        b."area_land_meters"                  AS block_area_m2
    FROM co_zips z
    JOIN FDA.GEO_CENSUS_BLOCKGROUPS."US_BLOCKGROUPS_NATIONAL" b
      ON ST_INTERSECTS(
           z.zip_geom,
           TO_GEOGRAPHY(b."blockgroup_geom")
         )
),
overlap_ratio AS (              -- 4. Overlap ratio for each pair
    SELECT
        zip_code,
        geo_id,
        CASE
            WHEN block_area_m2 > 0
                 THEN intersect_area_m2 / block_area_m2
            ELSE 0
        END AS overlap_ratio
    FROM zip_block_overlap
    WHERE intersect_area_m2 > 0
),
distributed_bank_counts AS (    -- 5. Distribute bank counts by ratio
    SELECT
        o.zip_code,
        o.geo_id,
        o.overlap_ratio * COALESCE(c.bank_locations,0)
            AS bank_locations_to_block
    FROM overlap_ratio        o
    LEFT JOIN co_bank_counts  c
           ON o.zip_code = c.zip_code
),
zip_concentration AS (          -- 6. Peak concentration per ZIP
    SELECT
        zip_code,
        MAX(bank_locations_to_block) AS max_banks_in_blockgroup
    FROM distributed_bank_counts
    GROUP BY zip_code
),
ranked AS (                     -- 7. Rank ZIP codes by peak value
    SELECT
        zip_code,
        max_banks_in_blockgroup,
        ROW_NUMBER() OVER (
            ORDER BY max_banks_in_blockgroup DESC NULLS LAST
        ) AS rn
    FROM zip_concentration
)
SELECT
    zip_code                               AS "COLORADO_ZIP_WITH_HIGHEST_BANK_CONCENTRATION",
    ROUND(max_banks_in_blockgroup,4)       AS "MAX_BANKS_PER_BLOCKGROUP"
FROM ranked
WHERE rn = 1;