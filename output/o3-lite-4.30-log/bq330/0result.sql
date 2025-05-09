WITH co_banks AS (
  SELECT
    zip_code,
    COUNT(1) AS bank_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
  GROUP BY zip_code
),
co_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),
co_bgs AS (
  SELECT
    geo_id,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'
),
overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) /
    ST_AREA(bg.blockgroup_geom) AS overlap_ratio
  FROM co_zips AS z
  JOIN co_bgs AS bg
  ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) > 0
),
assigned AS (
  SELECT
    o.zip_code,
    o.geo_id,
    o.overlap_ratio * b.bank_count AS est_bank_to_bg
  FROM overlap AS o
  JOIN co_banks AS b
  ON o.zip_code = b.zip_code
),
zip_concentration AS (
  SELECT
    zip_code,
    SUM(est_bank_to_bg) / COUNT(DISTINCT geo_id) AS banks_per_block_group
  FROM assigned
  GROUP BY zip_code
)
SELECT
  zip_code,
  ROUND(banks_per_block_group, 4) AS banks_per_block_group
FROM zip_concentration
ORDER BY banks_per_block_group DESC, zip_code
LIMIT 1;