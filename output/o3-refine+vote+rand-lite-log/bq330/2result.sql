WITH colorado_bank_counts AS (
  -- Number of bank locations per Colorado ZIP code
  SELECT
    LPAD(zip_code, 5, '0') AS zip_code,
    COUNT(*)              AS bank_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'                      -- Colorado locations only
    AND zip_code IS NOT NULL
  GROUP BY zip_code
),
zip_blockgroup_counts AS (
  -- How many census block‑groups intersect each Colorado ZIP code
  SELECT
    z.zip_code,
    COUNT(DISTINCT b.geo_id) AS blockgroup_count
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`               AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` AS b
  ON  ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
  WHERE z.state_code     = 'CO'    -- Colorado ZIP geometries
    AND b.state_fips_code = '08'   -- Colorado block‑groups
  GROUP BY z.zip_code
),
zip_concentration AS (
  -- Combine counts and compute “banks per block‑group”
  SELECT
    b.zip_code,
    b.bank_count,
    g.blockgroup_count,
    SAFE_DIVIDE(b.bank_count, g.blockgroup_count) AS banks_per_blockgroup
  FROM colorado_bank_counts      AS b
  JOIN zip_blockgroup_counts     AS g
  USING (zip_code)
)
-- ZIP code with the highest concentration of bank locations per block‑group
SELECT
  zip_code,
  bank_count,
  blockgroup_count,
  banks_per_blockgroup
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC, zip_code
LIMIT 1;