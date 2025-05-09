-- Colorado ZIP code with the highest concentration of bank locations
WITH
  -- Colorado ZIP-code geometries
  colorado_zips AS (
    SELECT
      zip_code,
      zip_code_geom
    FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
    WHERE state_code = 'CO'
  ),

  -- Colorado Census block-group geometries
  colorado_blockgroups AS (
    SELECT
      geo_id,
      blockgroup_geom
    FROM `bigquery-public-data.geo_census_blockgroups.blockgroups_08`
  ),

  -- Number of block groups that intersect each ZIP code
  blockgroups_per_zip AS (
    SELECT
      z.zip_code,
      COUNT(DISTINCT b.geo_id) AS blockgroup_cnt
    FROM colorado_zips AS z
    JOIN colorado_blockgroups AS b
      ON ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
    GROUP BY z.zip_code
  ),

  -- Number of FDIC-listed bank locations in each ZIP code
  banks_per_zip AS (
    SELECT
      zip_code,
      COUNT(*) AS bank_locations
    FROM `bigquery-public-data.fdic_banks.locations`
    WHERE state = 'CO'
    GROUP BY zip_code
  )

-- Combine the two measures and return the ZIP with the highest ratio
SELECT
  bp.zip_code                         AS colorado_zip_with_highest_bank_concentration,
  SAFE_DIVIDE(bp.bank_locations, bg.blockgroup_cnt) AS banks_per_blockgroup,
  bp.bank_locations                   AS total_bank_locations,
  bg.blockgroup_cnt                   AS total_blockgroups
FROM banks_per_zip AS bp
JOIN blockgroups_per_zip AS bg
  ON bp.zip_code = bg.zip_code
ORDER BY banks_per_blockgroup DESC
LIMIT 1;