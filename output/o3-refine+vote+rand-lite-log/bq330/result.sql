-- Colorado ZIP code with the highest concentration of bank locations
-- (bank branches per overlapping census block‑group), using area‑weighted
-- distribution of branches to block‑groups.

WITH co_zips AS (   -- Colorado ZIP polygons
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

co_bank_counts AS (   -- number of FDIC bank locations per CO ZIP
  SELECT
    LPAD(REGEXP_EXTRACT(zip_code, r'(\d{5})'), 5, '0') AS zip_code,
    COUNT(*) AS bank_branches
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'         -- use CO branches only
  GROUP BY zip_code
),

zips_with_banks AS (        -- keep only ZIPs that have banks
  SELECT z.zip_code,
         z.zip_code_geom,
         b.bank_branches
  FROM   co_zips          AS z
  JOIN   co_bank_counts   AS b
  USING  (zip_code)
),

co_blockgroups AS (         -- Colorado census block‑groups
  SELECT
    geo_id,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'     -- Colorado
),

-- intersection of each ZIP with each overlapping block‑group
zip_bg_overlap AS (
  SELECT
    z.zip_code,
    bg.geo_id,
    z.bank_branches,
    ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) AS overlap_area,
    ST_AREA(bg.blockgroup_geom)                                   AS bg_area
  FROM zips_with_banks z
  JOIN co_blockgroups bg
  ON  ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
),

-- distribute bank branches to block‑groups by overlap ratio
distributed_banks AS (
  SELECT
    zip_code,
    geo_id,
    bank_branches * (overlap_area / bg_area) AS banks_in_bg
  FROM zip_bg_overlap
  WHERE overlap_area > 0
),

-- concentration = (area‑weighted) branches per block‑group
zip_concentration AS (
  SELECT
    zip_code,
    SUM(banks_in_bg)                     AS total_banks,
    COUNT(DISTINCT geo_id)               AS blockgroup_ct,
    SAFE_DIVIDE(SUM(banks_in_bg),
                COUNT(DISTINCT geo_id))  AS banks_per_blockgroup
  FROM distributed_banks
  GROUP BY zip_code
)

SELECT
  zip_code
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;