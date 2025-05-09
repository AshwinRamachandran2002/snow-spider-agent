-- Colorado ZIP code with the highest concentration of bank locations
-- (expected bank locations per intersecting Census block‑group)

WITH
/* 1.  Colorado ZIP‑code geometries */
co_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

/* 2.  Colorado Census block‑group geometries */
co_blockgroups AS (
  SELECT
    geo_id,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'   -- Colorado
),

/* 3.  Area overlap between each ZIP and each block‑group */
zip_bg_overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    ST_Area(ST_Intersection(z.zip_code_geom, bg.blockgroup_geom))      AS intersect_area,
    ST_Area(bg.blockgroup_geom)                                        AS bg_area
  FROM co_zips z
  JOIN co_blockgroups bg
  ON ST_Intersects(z.zip_code_geom, bg.blockgroup_geom)
  WHERE ST_Area(ST_Intersection(z.zip_code_geom, bg.blockgroup_geom)) > 0
),

/* 4.  Overlap ratio (share of the block‑group that lies in the ZIP) */
zip_bg_ratio AS (
  SELECT
    zip_code,
    geo_id,
    intersect_area / bg_area AS ratio
  FROM zip_bg_overlap
),

/* 5.  Number of FDIC bank locations per Colorado ZIP */
co_bank_counts AS (
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip_code,
    COUNT(*)               AS bank_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'             -- Colorado branches
    AND zip_code IS NOT NULL
  GROUP BY 1
),

/* 6.  Distribute bank counts to block‑groups via overlap ratio
       and compute “banks per block‑group” concentration for each ZIP */
zip_concentration AS (
  SELECT
    r.zip_code,
    bc.bank_count,
    SUM(r.ratio)                    AS sum_overlap_ratio,
    COUNT(*)                        AS blockgroup_cnt,
    -- expected banks per block‑group
    (bc.bank_count * SUM(r.ratio)) / COUNT(*) AS banks_per_blockgroup
  FROM zip_bg_ratio r
  JOIN co_bank_counts bc
  USING (zip_code)
  GROUP BY r.zip_code, bc.bank_count
)

/* 7.  ZIP with the highest concentration */
SELECT
  zip_code,
  banks_per_blockgroup
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;