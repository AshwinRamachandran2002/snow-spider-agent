-- Colorado ZIP code with the highest concentration of bank locations
-- (number of bank branches divided by the number of Census block groups
-- that spatially intersect the ZIP)

WITH co_zips AS (   -- all Colorado ZIP‑code polygons
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

co_bgs AS (         -- all Colorado Census block‑group polygons
  SELECT
    geo_id,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'      -- Colorado
),

zip_bg_counts AS (  -- how many block groups each ZIP intersects
  SELECT
    z.zip_code,
    COUNT(DISTINCT bg.geo_id) AS num_blockgroups
  FROM co_zips AS z
  JOIN co_bgs AS bg
  ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  GROUP BY z.zip_code
),

bank_counts AS (    -- number of FDIC bank locations per ZIP (Colorado only)
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip_code,
    COUNT(*)             AS bank_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'                       -- Colorado records
  GROUP BY SUBSTR(zip_code, 1, 5)
),

zip_concentration AS (
  SELECT
    z.zip_code,
    b.bank_count,
    z.num_blockgroups,
    SAFE_DIVIDE(b.bank_count, z.num_blockgroups) AS banks_per_blockgroup
  FROM zip_bg_counts AS z
  LEFT JOIN bank_counts AS b
  USING (zip_code)
)

SELECT
  zip_code
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;