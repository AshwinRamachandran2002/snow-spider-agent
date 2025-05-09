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