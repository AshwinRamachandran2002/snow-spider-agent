/* Colorado ZIP code with the highest concentration of bank locations
   per census block‑group (banks distributed by ZIP/BG area‑overlap) */

WITH co_bank_per_zip AS (
  SELECT
    LPAD(REGEXP_EXTRACT(zip_code, r'(\d{5})'), 5, '0') AS zip_code,
    COUNT(*)                                           AS bank_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
    AND REGEXP_CONTAINS(zip_code, r'\d{5}')
  GROUP BY zip_code
),

zip_bg_overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    ST_AREA( ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom) )
      / ST_AREA(bg.blockgroup_geom)                    AS overlap_ratio
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`            AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` AS bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE z.state_code = 'CO'
    AND bg.state_fips_code = '08'
),

banks_distributed AS (
  SELECT
    o.zip_code,
    o.geo_id,
    o.overlap_ratio * b.bank_locations                AS banks_to_bg
  FROM zip_bg_overlap AS o
  JOIN co_bank_per_zip AS b
  USING (zip_code)
)

SELECT
  zip_code,
  ROUND( SUM(banks_to_bg) / COUNT(DISTINCT geo_id), 4 ) AS banks_per_block_group
FROM banks_distributed
GROUP BY zip_code
ORDER BY banks_per_block_group DESC, zip_code
LIMIT 1;