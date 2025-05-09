-- Colorado ZIP code with the highest concentration of bank locations per block‑group
WITH
/* 1. Colorado ZIP‑code geometries */
co_zips AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

/* 2. Colorado census block‑group geometries (land area only) */
co_blockgroups AS (
  SELECT
    geo_id,
    blockgroup_geom,
    area_land_meters                       -- used as denominator for overlap ratio
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'             -- Colorado
    AND area_land_meters > 0               -- avoid divide‑by‑zero
),

/* 3. Overlap ratio of each ZIP with every intersecting block‑group          */
/*    ratio = intersection_area / block‑group_land_area                      */
zip_bg_overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom))
      / bg.area_land_meters                             AS overlap_ratio
  FROM co_zips z
  JOIN co_blockgroups bg
    ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
),

/* 4. “Effective” number of block‑groups inside each ZIP.                    */
/*    (Sum of overlap ratios ≈ number of whole block‑groups covered)         */
zip_effective_bg AS (
  SELECT
    zip_code,
    SUM(overlap_ratio) AS effective_blockgroups
  FROM zip_bg_overlap
  GROUP BY zip_code
),

/* 5. Count of FDIC bank locations per Colorado ZIP                          */
zip_bank_counts AS (
  SELECT
    zip_code,
    COUNT(*) AS bank_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND zip_code IS NOT NULL
  GROUP BY zip_code
),

/* 6. Concentration = banks ÷ effective block‑groups                         */
zip_concentration AS (
  SELECT
    b.zip_code,
    b.bank_locations,
    e.effective_blockgroups,
    b.bank_locations / e.effective_blockgroups AS banks_per_blockgroup
  FROM zip_bank_counts b
  JOIN zip_effective_bg  e
    ON b.zip_code = e.zip_code
)

SELECT
  zip_code,
  bank_locations,
  ROUND(effective_blockgroups, 2)  AS effective_blockgroups,
  ROUND(banks_per_blockgroup, 4)   AS banks_per_blockgroup
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;