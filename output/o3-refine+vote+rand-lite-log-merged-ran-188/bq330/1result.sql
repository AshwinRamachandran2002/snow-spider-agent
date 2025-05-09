/*  Colorado ZIP code with the greatest “bank–per–block-group” concentration
    (banks are apportioned to census block groups according to the land-area
     overlap between ZIP-code polygons and block-group polygons)              */

WITH
-- 1. Colorado ZIP-code geometries
co_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

-- 2. FDIC-insured bank-branch counts per Colorado ZIP
co_zip_bank_counts AS (
  SELECT
    zip_code,
    COUNT(*) AS bank_locs
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
  GROUP BY zip_code
),

-- 3. Colorado census block-group geometries
co_blockgroups AS (
  SELECT
    geo_id,
    blockgroup_geom,
    area_land_meters
  FROM `bigquery-public-data.geo_census_blockgroups.blockgroups_08`
  WHERE area_land_meters > 0                      -- avoid divide-by-zero
),

-- 4. Area of overlap between each ZIP and each intersecting block group
zip_bg_overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id  AS blockgroup_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) AS intersect_area_m2,
    bg.area_land_meters,
    bc.bank_locs
  FROM co_zips            AS z
  JOIN co_zip_bank_counts AS bc  ON bc.zip_code = z.zip_code
  JOIN co_blockgroups     AS bg  ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) > 0
),

-- 5. Distribute each ZIP’s banks to its block groups, weighted by overlap
banks_per_blockgroup AS (
  SELECT
    zip_code,
    blockgroup_id,
    bank_locs * (intersect_area_m2 / area_land_meters) AS banks_est
  FROM zip_bg_overlap
),

-- 6. For every ZIP, compute average banks per intersecting block group
zip_concentration AS (
  SELECT
    zip_code,
    SUM(banks_est) / COUNT(DISTINCT blockgroup_id) AS banks_per_blockgroup
  FROM banks_per_blockgroup
  GROUP BY zip_code
)

-- 7. ZIP with the highest concentration
SELECT
  zip_code,
  ROUND(banks_per_blockgroup, 2) AS banks_per_blockgroup
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;