-- Colorado ZIP code with the highest average number of bank locations per block group
WITH co_banks AS (                        -- 1.  Bank locations per 5‑digit CO ZIP
  SELECT
    LPAD(SUBSTR(zip_code, 1, 5), 5, '0') AS zip5,
    COUNT(*) AS bank_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
  GROUP BY zip5
),
co_zip_geoms AS (                         -- 2.  Colorado ZIP polygons that have banks
  SELECT
    z.zip_code AS zip5,
    z.zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  JOIN co_banks AS b
    ON z.zip_code = b.zip5
  WHERE z.state_code = 'CO'
),
co_blockgroups AS (                       -- 3.  Colorado block‑group geometries
  SELECT
    geo_id,
    blockgroup_geom,
    SAFE_CAST(area_land_meters AS FLOAT64) AS land_area
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'            -- Colorado
),
zip_blockgroup_overlap AS (               -- 4.  Intersection area ZIP × block group
  SELECT
    z.zip5,
    b.geo_id AS blockgroup_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, b.blockgroup_geom)) AS inter_area,
    b.land_area
  FROM co_zip_geoms AS z
  JOIN co_blockgroups AS b
    ON ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
),
distributed AS (                          -- 5.  Overlap ratio
  SELECT
    zip5,
    blockgroup_id,
    CASE
      WHEN land_area > 0 THEN inter_area / land_area
      ELSE 0
    END AS overlap_ratio
  FROM zip_blockgroup_overlap
  WHERE inter_area > 0
),
banks_distributed AS (                    -- 6.  Distribute banks to block groups
  SELECT
    d.zip5,
    d.blockgroup_id,
    d.overlap_ratio * b.bank_count AS bank_share
  FROM distributed AS d
  JOIN co_banks AS b
    USING (zip5)
),
zip_stats AS (                            -- 7.  Banks per block group for each ZIP
  SELECT
    zip5,
    SUM(bank_share)                        AS total_distributed_banks,
    COUNT(DISTINCT blockgroup_id)          AS blockgroup_cnt,
    SAFE_DIVIDE(SUM(bank_share), COUNT(DISTINCT blockgroup_id)) AS banks_per_blockgroup
  FROM banks_distributed
  GROUP BY zip5
)
-- 8.  ZIP with the highest concentration
SELECT
  zip5 AS colorado_zip_with_highest_bank_concentration,
  banks_per_blockgroup
FROM zip_stats
ORDER BY banks_per_blockgroup DESC
LIMIT 1;