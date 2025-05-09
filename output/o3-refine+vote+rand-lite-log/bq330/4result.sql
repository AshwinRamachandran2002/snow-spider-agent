-- Colorado ZIP code with the greatest average number of bank locations per block‑group
WITH co_zip AS (
  SELECT
    z.zip_code                                AS zip5,
    z.zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  WHERE z.state_code = 'CO'                          -- Colorado only
),

bank_zip_counts AS (                                -- FDIC branches counted by 5‑digit ZIP
  SELECT
    REGEXP_EXTRACT(zip_code, r'^(\d{5})') AS zip5,
    COUNT(*)                                       AS bank_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
    AND REGEXP_CONTAINS(zip_code, r'^\d{5}')       -- keep clean 5‑digit codes
  GROUP BY zip5
),

co_blockgroups AS (                                 -- Colorado census block‑groups
  SELECT
    bg.geo_id,
    bg.blockgroup_geom,
    bg.area_land_meters
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` AS bg
  WHERE bg.state_fips_code = '08'                   -- 08 = Colorado
),

-- intersection between each ZIP and the block‑groups it overlaps
zip_bg_overlap AS (
  SELECT
    z.zip5,
    bg.geo_id                       AS blockgroup_id,
    bg.area_land_meters,
    b.bank_cnt,
    ST_AREA(
      ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)
    )                                AS overlap_area
  FROM co_zip            AS z
  JOIN bank_zip_counts   AS b  ON b.zip5 = z.zip5
  JOIN co_blockgroups    AS bg ON ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
),

-- distribute ZIP‑level bank counts to block‑groups by overlap ratio
distributed AS (
  SELECT
    zip5,
    blockgroup_id,
    bank_cnt * (overlap_area / NULLIF(area_land_meters,0)) AS distributed_banks
  FROM zip_bg_overlap
  WHERE overlap_area > 0
),

-- average (banks per block‑group) for each ZIP
zip_concentration AS (
  SELECT
    zip5,
    SUM(distributed_banks) / COUNT(DISTINCT blockgroup_id) AS banks_per_blockgroup
  FROM distributed
  GROUP BY zip5
)

SELECT
  zip5 AS colorado_zip_with_highest_bank_concentration
FROM zip_concentration
ORDER BY banks_per_blockgroup DESC
LIMIT 1;