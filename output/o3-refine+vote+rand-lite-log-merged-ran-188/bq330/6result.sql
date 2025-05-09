WITH co_zip_geom AS (
  -- Colorado ZIP-code geometries
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),
co_zip_banks AS (
  -- Count of FDIC-listed bank locations in each Colorado ZIP code
  SELECT
    zip_code,
    COUNT(*) AS bank_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
    AND REGEXP_CONTAINS(zip_code, r'^\d{5}$')         -- keep 5-digit ZIPs
  GROUP BY zip_code
),
zip_bg_overlap AS (
  -- Portion of every census block group that falls inside each ZIP
  SELECT
    z.zip_code,
    bg.geo_id AS blockgroup_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) /
    ST_AREA(bg.blockgroup_geom)                       AS overlap_ratio
  FROM co_zip_geom z
  JOIN `bigquery-public-data.geo_census_blockgroups.blockgroups_08` bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE ST_AREA(bg.blockgroup_geom) > 0               -- guard against zero area
)
-- Calculate average bank locations per overlapped block group
SELECT
  zb.zip_code,
  SUM(czb.bank_cnt * zb.overlap_ratio) /
  COUNT(DISTINCT zb.blockgroup_id)                    AS banks_per_blockgroup
FROM zip_bg_overlap zb
JOIN co_zip_banks czb
  ON zb.zip_code = czb.zip_code
GROUP BY zb.zip_code
ORDER BY banks_per_blockgroup DESC
LIMIT 1;