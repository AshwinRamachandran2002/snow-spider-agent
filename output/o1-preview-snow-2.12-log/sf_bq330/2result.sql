WITH bank_counts AS (
  SELECT 
    "zip_code", 
    COUNT(*) AS "bank_count"
  FROM 
    "FDA"."FDIC_BANKS"."LOCATIONS"
  WHERE 
    "state" = 'CO'
  GROUP BY 
    "zip_code"
),
blockgroup_counts AS (
  SELECT 
    zc."zip_code",
    COUNT(DISTINCT bg."geo_id") AS "blockgroup_count"
  FROM
    "FDA"."GEO_US_BOUNDARIES"."ZIP_CODES" zc
  INNER JOIN
    "FDA"."GEO_CENSUS_BLOCKGROUPS"."BLOCKGROUPS_08" bg
    ON ST_INTERSECTS(
      ST_GEOGFROMWKB(zc."zip_code_geom"),
      ST_GEOGFROMWKB(bg."blockgroup_geom")
    )
  WHERE
    zc."state_code" = 'CO'
  GROUP BY
    zc."zip_code"
)
SELECT
  bc."zip_code",
  ROUND(bc."bank_count" / bgc."blockgroup_count", 4) AS "bank_locations_per_block_group"
FROM
  bank_counts bc
JOIN
  blockgroup_counts bgc
ON
  bc."zip_code" = bgc."zip_code"
ORDER BY
  "bank_locations_per_block_group" DESC NULLS LAST
LIMIT 1;