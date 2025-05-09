-- Colorado ZIP code with the highest average number of bank locations
-- per census block-group (area-weighted)

WITH branches_per_zip AS (
  -- 1. How many FDIC branches fall inside each Colorado ZIP code?
  SELECT
    zip_code,
    COUNT(*) AS branch_cnt
  FROM
    `bigquery-public-data.fdic_banks.locations`
  WHERE
    state      = 'CO'            -- Colorado only
    AND zip_code IS NOT NULL
  GROUP BY
    zip_code
),

bg_shares AS (
  -- 2. Distribute each ZIP’s branches to the Colorado block-groups it overlaps,
  --    in proportion to the share of the block-group’s area that lies inside
  --    the ZIP code polygon.
  SELECT
    bg.geo_id                     AS blockgroup_geo_id,
    z.zip_code,
    bpz.branch_cnt
      * ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom))
      / NULLIF(ST_AREA(bg.blockgroup_geom),0)        AS branch_share
  FROM
    `bigquery-public-data.geo_us_boundaries.zip_codes`                    AS z
  JOIN
    branches_per_zip                                                   AS bpz
    ON  bpz.zip_code = z.zip_code
  JOIN
    `bigquery-public-data.geo_census_blockgroups.blockgroups_08`         AS bg
    ON  ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
  WHERE
    z.state_code = 'CO'                                -- Colorado ZIPs
    AND ST_AREA(ST_INTERSECTION(z.zip_code_geom, bg.blockgroup_geom)) > 0
)

-- 3. Average the distributed branch counts across the block-groups
--    within each ZIP code and return the ZIP with the maximum value.
SELECT
  zip_code,
  SUM(branch_share) / COUNT(DISTINCT blockgroup_geo_id) AS branches_per_blockgroup
FROM
  bg_shares
GROUP BY
  zip_code
ORDER BY
  branches_per_blockgroup DESC
LIMIT 1;