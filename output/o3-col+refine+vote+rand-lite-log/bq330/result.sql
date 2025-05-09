-- Colorado ZIP code with the highest concentration of FDIC bank locations
WITH bank_branches AS (
  SELECT
    zip_code,
    COUNT(*) AS bank_branch_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'           -- Colorado only
    AND LENGTH(zip_code) = 5   -- keep standard 5-digit ZIP codes
  GROUP BY zip_code
),
blockgroups_per_zip AS (
  SELECT
    z.zip_code,
    COUNT(DISTINCT bg.geo_id) AS blockgroup_count
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`           AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.blockgroups_08` AS bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE z.state_code = 'CO'    -- Colorado ZIP-code polygons
  GROUP BY z.zip_code
)
SELECT
  b.zip_code,
  bank_branch_count,
  blockgroup_count,
  SAFE_DIVIDE(bank_branch_count, blockgroup_count) AS branches_per_blockgroup
FROM bank_branches b
JOIN blockgroups_per_zip USING (zip_code)
ORDER BY branches_per_blockgroup DESC
LIMIT 1;