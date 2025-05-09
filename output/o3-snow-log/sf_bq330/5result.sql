/*---------------------------------------------------------------
  Colorado ZIP code with the highest concentration of bank
  locations per census block-group
----------------------------------------------------------------*/
WITH bank_zip AS (           -- 1) Bank locations per CO ZIP
    SELECT
        l."zip_code"                      AS zip_code,
        COUNT(*)                          AS bank_locations
    FROM FDA.FDIC_BANKS.LOCATIONS l
    WHERE l."state" = 'CO'
      AND l."zip_code" IS NOT NULL
    GROUP BY l."zip_code"
),

co_zip_geom AS (             -- 2) Geometry for CO ZIPs
    SELECT
        z."zip_code"                     AS zip_code,
        TO_GEOGRAPHY(z."zip_code_geom")  AS zip_geom
    FROM FDA.GEO_US_BOUNDARIES.ZIP_CODES z
    WHERE z."state_code" = 'CO'
),

zip_bank_geom AS (           -- 3) ZIPs that actually have banks
    SELECT
        b.zip_code,
        b.bank_locations,
        g.zip_geom
    FROM bank_zip      b
    JOIN co_zip_geom   g  ON b.zip_code = g.zip_code
),

blockgroups AS (             -- 4) Block-group geometries & areas
    SELECT
        bg."geo_id"                        AS geo_id,
        TO_GEOGRAPHY(bg."blockgroup_geom") AS bg_geom,
        (bg."area_land_meters" + bg."area_water_meters") AS bg_area
    FROM FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL bg
),

zip_bg_overlap AS (          -- 5) Area of overlap ZIP ↔ block-group
    SELECT
        z.zip_code,
        z.bank_locations,
        bg.geo_id,
        bg.bg_area,
        ST_AREA(
            ST_INTERSECTION(z.zip_geom, bg.bg_geom)
        ) AS intersect_area
    FROM zip_bank_geom z
    JOIN blockgroups  bg
      ON ST_INTERSECTS(z.zip_geom, bg.bg_geom)
),

zip_bg_ratio AS (            -- 6) Overlap ratio per ZIP–block-group
    SELECT
        zip_code,
        geo_id,
        CASE
            WHEN bg_area > 0 THEN intersect_area / bg_area
            ELSE 0
        END                                AS overlap_ratio,
        bank_locations
    FROM zip_bg_overlap
    WHERE intersect_area > 0
),

allocated AS (               -- 7) Allocate banks to block-groups
    SELECT
        zip_code,
        geo_id,
        overlap_ratio * bank_locations     AS bank_to_bg
    FROM zip_bg_ratio
),

zip_concentration AS (       -- 8) Banks per block-group within ZIP
    SELECT
        zip_code,
        SUM(bank_to_bg)                    AS total_bank_locations,
        COUNT(DISTINCT geo_id)             AS blockgroup_count,
        SUM(bank_to_bg) / COUNT(DISTINCT geo_id) AS bank_per_blockgroup
    FROM allocated
    GROUP BY zip_code
)

SELECT
    zip_code,
    bank_per_blockgroup
FROM zip_concentration
ORDER BY bank_per_blockgroup DESC NULLS LAST
LIMIT 1;