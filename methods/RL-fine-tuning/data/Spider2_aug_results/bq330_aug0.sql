-- Task: Identify the Colorado zip code with the highest average weighted count of bank locations per block group, where the weighting is based on the proportion of each block group's area that overlaps with the zip code. The concentration is computed by summing these weighted counts and dividing by the number of distinct block groups overlapping with the zip code.

SELECT
  zip_code,
  ROUND(SUM(weighted_branch_count) / COUNT(DISTINCT geo_id), 4) AS Concentration
FROM (
  SELECT
    overlaps.zip_code,
    overlaps.geo_id,
    COUNT(l.branch_name) * SAFE_DIVIDE(overlaps.overlap_area, overlaps.blockgroup_area) AS weighted_branch_count
  FROM (
    SELECT
      z.zip_code,
      b.geo_id,
      ST_AREA(ST_INTERSECTION(z.zip_code_geom, b.blockgroup_geom)) AS overlap_area,
      ST_AREA(b.blockgroup_geom) AS blockgroup_area
    FROM
      `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
    INNER JOIN
      `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` AS b
    ON
      ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
    WHERE
      z.state_code = 'CO'
      AND b.state_fips_code = '08'
  ) AS overlaps
  INNER JOIN
    `bigquery-public-data.fdic_banks.locations` AS l
  ON
    l.zip_code = overlaps.zip_code
  WHERE
    l.state = 'CO' AND l.branch_name IS NOT NULL
  GROUP BY
    overlaps.zip_code,
    overlaps.geo_id,
    overlaps.overlap_area,
    overlaps.blockgroup_area
) AS sub
GROUP BY
  zip_code
ORDER BY
  Concentration DESC
LIMIT 1;