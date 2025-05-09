-- Colorado ZIP code with the highest number of bank locations per census block-group
WITH bank_counts AS (                       -- 1. Bank branches per 5-digit ZIP
  SELECT
    SUBSTR(zip_code, 1, 5)       AS zip5,
    COUNT(*)                     AS bank_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'                          -- Colorado branches only
    AND zip_code IS NOT NULL
  GROUP BY zip5
),
blockgroup_counts AS (                       -- 2. Block-groups intersecting each ZIP
  SELECT
    z.zip_code                   AS zip5,
    COUNT(DISTINCT bg.geo_id)    AS blockgroup_cnt
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`              AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.blockgroups_08`    AS bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE z.state_code = 'CO'                    -- Colorado ZIP polygons only
  GROUP BY z.zip_code
)

SELECT
  b.zip5                                   AS colorado_zip_with_max_bank_density,
  SAFE_DIVIDE(b.bank_cnt, g.blockgroup_cnt) AS banks_per_blockgroup
FROM bank_counts         b
JOIN blockgroup_counts   g  USING (zip5)
ORDER BY banks_per_blockgroup DESC          -- highest density first
LIMIT 1;