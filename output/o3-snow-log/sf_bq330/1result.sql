/*--------------------------------------------------------------------
   Colorado ZIP code with the highest concentration of bank locations
   per census block group   (Snowflake-compatible)
  ------------------------------------------------------------------*/

WITH bank_zip AS (           /* 1. # of bank locations in each CO ZIP */
    SELECT 
        "zip_code"                     AS zip_code ,
        COUNT(*)                       AS bank_count
    FROM   "FDA"."FDIC_BANKS"."LOCATIONS"
    WHERE  "state" = 'CO'
      AND  "zip_code" IS NOT NULL
    GROUP  BY "zip_code"
),

co_zip_geom AS (             /* 2. Colorado ZIP-code geometries       */
    SELECT
        z."zip_code"          AS zip_code ,
        z."zip_code_geom"     AS zip_geom
    FROM   "FDA"."GEO_US_BOUNDARIES"."ZIP_CODES" z
    WHERE  z."state_code" = 'CO'
),

bg AS (                      /* 3. All census block-group geometries  */
    SELECT
        "geo_id"              AS geo_id ,
        "blockgroup_geom"     AS bg_geom
    FROM   "FDA"."GEO_CENSUS_BLOCKGROUPS"."US_BLOCKGROUPS_NATIONAL"
),

overlaps AS (                /* 4. ZIP ↔ block-group intersections   */
    SELECT
        z.zip_code ,
        b.geo_id ,
        ST_AREA(
            ST_INTERSECTION(
                TO_GEOGRAPHY(z.zip_geom) ,
                TO_GEOGRAPHY(b.bg_geom)
            )
        ) AS intersection_area
    FROM   co_zip_geom  z
    JOIN   bg           b
      ON   ST_INTERSECTS(
               TO_GEOGRAPHY(z.zip_geom) ,
               TO_GEOGRAPHY(b.bg_geom)
           )
),

zip_bg_counts AS (           /* 5. # block groups intersecting a ZIP  */
    SELECT
        zip_code ,
        COUNT(DISTINCT geo_id) AS blockgroup_count
    FROM   overlaps
    WHERE  intersection_area > 0        -- keep true overlaps only
    GROUP  BY zip_code
),

zip_concentration AS (       /* 6. bank locations per block group     */
    SELECT
        zbc.zip_code ,
        COALESCE(bz.bank_count , 0)                    AS bank_count ,
        zbc.blockgroup_count ,
        COALESCE(bz.bank_count , 0)  / NULLIF(zbc.blockgroup_count , 0)
                                                AS concentration
    FROM   zip_bg_counts zbc
    LEFT  JOIN bank_zip     bz
           ON zbc.zip_code = bz.zip_code
)

SELECT
    zip_code ,
    bank_count ,
    blockgroup_count ,
    concentration
FROM   zip_concentration
ORDER  BY concentration DESC NULLS LAST
FETCH  FIRST 1 ROWS ONLY;