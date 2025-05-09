/* Colorado ZIP code with the highest concentration of bank locations
   per census block group (banks allocated by ZIP–block‑group overlap) */

WITH zip_bank_counts AS (
  -- 1. Raw bank‑branch counts per Colorado ZIP code
  SELECT
    zip_code,
    COUNT(*) AS bank_locations
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
  GROUP BY zip_code
),

zip_blockgroup_overlap AS (
  -- 2. Overlap ratio of each Colorado ZIP with each intersecting block group
  SELECT
    z.zip_code,
    b.geo_id,
    ST_Area(ST_Intersection(z.zip_code_geom, b.blockgroup_geom))
      / ST_Area(b.blockgroup_geom) AS overlap_ratio
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`           AS z
  JOIN `bigquery-public-data.geo_census_blockgroups.blockgroups_08` AS b
    ON ST_Intersects(z.zip_code_geom, b.blockgroup_geom)
  WHERE z.state_code = 'CO'
),

allocated_banks AS (
  -- 3. Allocate ZIP‑level bank counts to block groups by overlap ratio,
  --    then re‑aggregate to ZIP level to get:
  --    • estimated banks within ZIP   • number of block groups touched
  SELECT
    z.zip_code,
    SUM(zb.bank_locations * z.overlap_ratio) AS est_banks,
    COUNT(DISTINCT z.geo_id)                AS blockgroups
  FROM zip_blockgroup_overlap AS z
  JOIN zip_bank_counts       AS zb USING (zip_code)
  GROUP BY z.zip_code
)

-- 4. Identify the ZIP code with the highest bank‑per‑block‑group ratio
SELECT
  zip_code,
  est_banks,
  blockgroups,
  est_banks / blockgroups AS banks_per_blockgroup
FROM allocated_banks
ORDER BY banks_per_blockgroup DESC
LIMIT 1;