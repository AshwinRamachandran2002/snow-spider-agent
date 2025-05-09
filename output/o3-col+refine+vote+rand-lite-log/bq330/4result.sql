-- Which Colorado ZIP code has the highest concentration of bank locations per block group?
WITH banks_per_zip AS (
  -- 1.  Count FDIC-insured bank locations in each Colorado ZIP code
  SELECT
    zip_code,
    COUNT(*) AS bank_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
  GROUP BY zip_code
),
zip_bg_overlap AS (
  -- 2.  For Colorado ZIPs, find intersecting census block-groups and
  --     compute the share of each block-group that lies inside the ZIP
  SELECT
    z.zip_code,
    b.geo_id                      AS blockgroup_id,
    ST_AREA(
      ST_INTERSECTION(z.zip_code_geom, b.blockgroup_geom)
    ) / NULLIF(ST_AREA(b.blockgroup_geom), 0)  AS overlap_ratio
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`           AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.blockgroups_08` AS b
    ON ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
  WHERE z.state_code = 'CO'
),
alloc AS (
  -- 3.  Allocate each ZIP’s bank locations to overlapping block-groups
  SELECT
    o.blockgroup_id,
    o.zip_code,
    COALESCE(bp.bank_locations, 0) * o.overlap_ratio AS banks_allocated
  FROM zip_bg_overlap o
  LEFT JOIN banks_per_zip bp
    ON o.zip_code = bp.zip_code
)
-- 4.  Compute concentration = (banks allocated) ÷ (# block-groups touched)
SELECT
  zip_code,
  SUM(banks_allocated)                           AS total_bank_locations,
  COUNT(DISTINCT blockgroup_id)                  AS blockgroups_count,
  SAFE_DIVIDE(SUM(banks_allocated),
              COUNT(DISTINCT blockgroup_id))     AS banks_per_blockgroup
FROM alloc
GROUP BY zip_code
ORDER BY banks_per_blockgroup DESC
LIMIT 1;