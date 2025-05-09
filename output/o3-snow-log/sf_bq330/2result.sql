/*--------------------------------------------------------------------
  Find the Colorado ZIP code with the highest concentration of
  bank branch locations per census block-group.
--------------------------------------------------------------------*/
WITH
/*--------------------------------------------------------------------
1.  Count branch locations in each Colorado ZIP code
--------------------------------------------------------------------*/
co_zip_branches AS (
    SELECT
        "zip_code"                        AS ZIP_CODE,          -- cast to upper-case identifier
        COUNT(*)                          AS BRANCH_COUNT
    FROM  FDA.FDIC_BANKS.LOCATIONS
    WHERE "state"    = 'CO'
      AND "zip_code" IS NOT NULL
    GROUP BY "zip_code"
),

/*--------------------------------------------------------------------
2.  Colorado ZIP-code geometries
--------------------------------------------------------------------*/
co_zips AS (
    SELECT
        z."zip_code"                      AS ZIP_CODE,          -- alias un-quoted → upper-case
        TO_GEOGRAPHY(z."zip_code_geom")   AS ZIP_GEOM
    FROM  FDA.GEO_US_BOUNDARIES.ZIP_CODES  z
    WHERE z."state_code" = 'CO'
),

/*--------------------------------------------------------------------
3.  Colorado census block-group geometries  (FIPS state code 08)
--------------------------------------------------------------------*/
co_blockgroups AS (
    SELECT
        bg."geo_id"                       AS GEO_ID,
        bg."area_land_meters"             AS AREA_LAND_M2,
        TO_GEOGRAPHY(bg."blockgroup_geom") AS BG_GEOM
    FROM  FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL  bg
    WHERE LEFT(bg."geo_id", 2) = '08'      -- Colorado
),

/*--------------------------------------------------------------------
4.  Intersect ZIPs with block-groups; keep only ZIPs that have branches
--------------------------------------------------------------------*/
zip_bg_overlap AS (
    SELECT
        z.ZIP_CODE,
        bg.GEO_ID,
        ST_INTERSECTION(z.ZIP_GEOM , bg.BG_GEOM)   AS INTER_GEOM,
        bg.AREA_LAND_M2,
        b.BRANCH_COUNT
    FROM        co_zips         z
    JOIN        co_zip_branches b  ON b.ZIP_CODE = z.ZIP_CODE        -- only ZIPs with branches
    JOIN        co_blockgroups  bg ON ST_INTERSECTS(z.ZIP_GEOM , bg.BG_GEOM)
),

/*--------------------------------------------------------------------
5.  Compute overlap ratio for each ZIP–block-group pair
--------------------------------------------------------------------*/
overlap_alloc AS (
    SELECT
        ZIP_CODE,
        GEO_ID,
        ST_AREA(INTER_GEOM)                                AS INTER_AREA_M2,
        CASE
             WHEN AREA_LAND_M2 = 0 THEN 0
             ELSE ST_AREA(INTER_GEOM) / AREA_LAND_M2
        END                                                AS OVERLAP_RATIO,
        BRANCH_COUNT
    FROM zip_bg_overlap
),

/*--------------------------------------------------------------------
6.  Allocate branches to block-groups proportionally to overlap
--------------------------------------------------------------------*/
bg_branch_alloc AS (
    SELECT
        ZIP_CODE,
        GEO_ID,
        OVERLAP_RATIO * BRANCH_COUNT      AS ALLOCATED_BRANCHES
    FROM overlap_alloc
)

/*--------------------------------------------------------------------
7.  Aggregate by ZIP code and rank by branch concentration
--------------------------------------------------------------------*/
SELECT
    ZIP_CODE                               AS COLORADO_ZIP_CODE,
    ROUND( SUM(ALLOCATED_BRANCHES)
           / NULLIF(COUNT(DISTINCT GEO_ID),0)
         , 4)                              AS BANK_LOCATIONS_PER_BLOCKGROUP,
    SUM(ALLOCATED_BRANCHES)                AS TOTAL_BANK_LOCATIONS_DISTRIBUTED,
    COUNT(DISTINCT GEO_ID)                 AS BLOCKGROUP_COUNT
FROM bg_branch_alloc
GROUP BY ZIP_CODE
ORDER BY BANK_LOCATIONS_PER_BLOCKGROUP DESC NULLS LAST
LIMIT 1;