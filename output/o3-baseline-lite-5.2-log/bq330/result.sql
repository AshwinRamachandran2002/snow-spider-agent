-- Colorado ZIP code with the highest concentration of bank locations
--   (bank‑branches per intersecting census block group)

WITH
/* 1.  Colorado ZIP‑code geometries  */
co_zip AS (
  SELECT
    zip_code,                       -- 5‑digit ZIP
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'           -- Colorado only
),

/* 2.  Colorado census block‑group geometries */
co_bg AS (
  SELECT
    geo_id,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.blockgroups_08`    -- 08 = CO
),

/* 3.  How many block groups intersect each ZIP */
zip_bg_count AS (
  SELECT
    z.zip_code,
    COUNT(DISTINCT b.geo_id) AS blockgroup_cnt
  FROM co_zip z
  JOIN co_bg  b
  ON ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
  GROUP BY z.zip_code
),

/* 4.  Number of FDIC bank locations in each ZIP (based on branch ZIP) */
zip_bank_count AS (
  SELECT
    SUBSTR(zip_code, 1, 5) AS zip_code,          -- keep 5‑digit part
    COUNT(*)               AS bank_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'                             -- Colorado branches
  GROUP BY zip_code
),

/* 5.  Combine counts & compute concentration (banks per block group) */
zip_stats AS (
  SELECT
    z.zip_code,
    IFNULL(b.bank_cnt, 0)      AS bank_cnt,
    bg.blockgroup_cnt,
    IFNULL(b.bank_cnt, 0) / bg.blockgroup_cnt AS banks_per_blockgroup
  FROM zip_bg_count bg
  JOIN co_zip            z ON z.zip_code = bg.zip_code
  LEFT JOIN zip_bank_count b ON b.zip_code = z.zip_code
)

SELECT
  zip_code,
  bank_cnt            AS total_bank_locations,
  blockgroup_cnt      AS total_block_groups,
  banks_per_blockgroup
FROM zip_stats
ORDER BY banks_per_blockgroup DESC, zip_code
LIMIT 1;