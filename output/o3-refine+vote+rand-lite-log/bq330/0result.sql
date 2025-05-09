-- Colorado ZIP code that shows the highest concentration of bank
-- locations in any single census block‑group (i.e. the ZIP whose
-- most‑banked block‑group contains the largest number of bank
-- locations once branch counts are proportionally distributed by
-- ZIP‑to‑block‑group land‑area overlap).

WITH
/* 1.  Colorado block groups (all of them, statewide) */
blockgroups AS (
  SELECT
    geo_id                    AS blkgp_id ,
    blockgroup_geom
  FROM `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national`
  WHERE state_fips_code = '08'            -- Colorado
),

/* 2.  Colorado ZIP‑code polygons */
zip_shapes AS (
  SELECT
    zip_code,
    zip_code_geom
  FROM `bigquery-public-data.geo_us_boundaries.zip_codes`
  WHERE state_code = 'CO'
),

/* 3.  ZIP ⇄ block‑group land‑area overlaps and their ratios         */
zip_blkgp_overlap AS (
  SELECT
    z.zip_code,
    b.blkgp_id,
    ST_AREA( ST_INTERSECTION(z.zip_code_geom , b.blockgroup_geom) )              AS intersect_area ,
    ST_AREA( b.blockgroup_geom )                                                 AS blkgp_area
  FROM zip_shapes z
  JOIN blockgroups  b
  ON  ST_INTERSECTS(z.zip_code_geom , b.blockgroup_geom)
  WHERE ST_AREA( ST_INTERSECTION(z.zip_code_geom , b.blockgroup_geom) ) > 0
),

overlap_ratios AS (
  SELECT
    zip_code,
    blkgp_id,
    intersect_area / blkgp_area                         AS overlap_ratio
  FROM zip_blkgp_overlap
),

/* 4.  Count of FDIC bank offices/branches per Colorado ZIP code     */
zip_bank_counts AS (
  SELECT
    zip_code,
    COUNT(*) AS branch_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'CO'
  GROUP BY zip_code
),

/* 5.  Distribute each ZIP’s branches to its intersecting block groups
       in proportion to the land‑area overlap ratio                  */
blkgp_bank_alloc AS (
  SELECT
    o.blkgp_id,
    o.zip_code,
    o.overlap_ratio * IFNULL(b.branch_cnt,0)        AS banks_from_zip
  FROM overlap_ratios o
  LEFT JOIN zip_bank_counts b  USING (zip_code)
),

/* 6.  Total banks (from that ZIP) sitting in each block‑group       */
blkgp_bank_totals AS (
  SELECT
    zip_code,
    blkgp_id,
    SUM(banks_from_zip) AS banks_in_blkgp
  FROM blkgp_bank_alloc
  GROUP BY zip_code, blkgp_id
),

/* 7.  For every ZIP, find the single block‑group with the most banks */
zip_max_blkgp AS (
  SELECT
    zip_code,
    MAX(banks_in_blkgp) AS max_banks_in_any_blkgp
  FROM blkgp_bank_totals
  GROUP BY zip_code
)

/* 8.  The Colorado ZIP having the highest such concentration         */
SELECT
  zip_code        AS colorado_zip_with_highest_bank_concentration,
  max_banks_in_any_blkgp
FROM zip_max_blkgp
ORDER BY max_banks_in_any_blkgp DESC
LIMIT 1;