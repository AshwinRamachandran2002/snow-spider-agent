-- Colorado ZIP code with the highest concentration of bank locations
WITH
  /* 1. Colorado ZIP-code geometries */
  co_zips AS (
    SELECT
      zip_code,
      zip_code_geom
    FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
    WHERE state_code = 'CO'
  ),

  /* 2. Colorado census block-group geometries */
  co_blockgroups AS (
    SELECT
      geo_id,
      blockgroup_geom
    FROM `bigquery-public-data.geo_census_blockgroups.blockgroups_08`
  ),

  /* 3. How many block groups each ZIP touches (spatial intersection) */
  zip_blockgroup_counts AS (
    SELECT
      z.zip_code,
      COUNT(DISTINCT bg.geo_id) AS blockgroup_cnt
    FROM co_zips AS z
    JOIN co_blockgroups AS bg
      ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
    GROUP BY z.zip_code
  ),

  /* 4. Number of FDIC bank branches in each Colorado ZIP code */
  bank_branches_per_zip AS (
    SELECT
      zip_code,
      COUNT(*) AS branch_cnt
    FROM `bigquery-public-data.fdic_banks.locations`
    WHERE state = 'CO'
    GROUP BY zip_code
  ),

  /* 5. Combine counts and compute concentration */
  zip_concentration AS (
    SELECT
      b.zip_code,
      b.branch_cnt,
      z.blockgroup_cnt,
      b.branch_cnt / z.blockgroup_cnt AS banks_per_blockgroup
    FROM bank_branches_per_zip AS b
    JOIN zip_blockgroup_counts   AS z
      USING (zip_code)
    WHERE z.blockgroup_cnt > 0          -- safety check
  )

/* 6. Return the ZIP code with the highest concentration */
SELECT
  zip_code                         AS colorado_zip_code,
  branch_cnt                       AS total_bank_branches,
  blockgroup_cnt                   AS overlapping_blockgroups,
  ROUND(banks_per_blockgroup, 3)   AS banks_per_blockgroup
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;