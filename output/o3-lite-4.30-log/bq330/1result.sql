WITH bank_counts AS (
  SELECT
    LPAD(zip_code,5,'0') AS zip_code,
    COUNT(*) AS branch_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
  GROUP BY zip_code
),
zip_bg_ratio AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom))
      / NULLIF(bg.area_land_meters,0) AS overlap_ratio
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` z
  JOIN `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE z.state_code = 'CO'
    AND bg.state_fips_code = '08'
),
distributed AS (
  SELECT
    r.zip_code,
    r.geo_id,
    b.branch_cnt * r.overlap_ratio AS branch_alloc
  FROM zip_bg_ratio r
  JOIN bank_counts  b
    ON r.zip_code = b.zip_code
  WHERE r.overlap_ratio > 0
),
zip_density AS (
  SELECT
    zip_code,
    SUM(branch_alloc) AS total_allocated_branches,
    COUNT(DISTINCT geo_id) AS blockgroup_cnt,
    SUM(branch_alloc) / COUNT(DISTINCT geo_id) AS banks_per_block_group
  FROM distributed
  GROUP BY zip_code
)
SELECT
  zip_code,
  ROUND(banks_per_block_group,4) AS banks_per_block_group
FROM zip_density
ORDER BY banks_per_block_group DESC, zip_code
LIMIT 1;