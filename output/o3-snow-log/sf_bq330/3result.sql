WITH banks_per_zip AS (
    /* 1.  Count Colorado bank locations per ZIP */
    SELECT
        TRIM("zip_code")           AS "zip_code",
        COUNT(*)                   AS "bank_count"
    FROM  FDA.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'CO'
      AND "zip_code" IS NOT NULL
    GROUP BY TRIM("zip_code")
),
zip_blockgroups AS (
    /* 2.  Pair every Colorado ZIP with the block groups whose geometry it overlaps */
    SELECT
        z."zip_code",
        g."geo_id"
    FROM  FDA.GEO_US_BOUNDARIES.ZIP_CODES                 z
    JOIN  FDA.GEO_CENSUS_BLOCKGROUPS.US_BLOCKGROUPS_NATIONAL g
      ON ST_INTERSECTS(
             TO_GEOGRAPHY(z."zip_code_geom"),
             TO_GEOGRAPHY(g."blockgroup_geom")
         )
    WHERE z."state_code" = 'CO'
),
blockgroups_per_zip AS (
    /* 3.  Count distinct block groups per ZIP */
    SELECT
        "zip_code",
        COUNT(DISTINCT "geo_id")   AS "blockgroup_count"
    FROM  zip_blockgroups
    GROUP BY "zip_code"
),
concentration AS (
    /* 4.  Calculate banks per block-group for each ZIP */
    SELECT
        b."zip_code",
        b."bank_count",
        bg."blockgroup_count",
        b."bank_count" / bg."blockgroup_count"  AS "banks_per_blockgroup"
    FROM  banks_per_zip       b
    JOIN  blockgroups_per_zip bg
          ON b."zip_code" = bg."zip_code"
    WHERE bg."blockgroup_count" > 0
)
SELECT
    "zip_code",
    "bank_count",
    "blockgroup_count",
    "banks_per_blockgroup"
FROM   concentration
ORDER BY "banks_per_blockgroup" DESC NULLS LAST
LIMIT 1;