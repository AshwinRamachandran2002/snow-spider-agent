-- Task: Can you provide the total distance traveled by each hurricane in the North Atlantic during 2020, ordered by total distance in descending order (limited to 100 results)?
WITH hurricane_geometry AS (
  SELECT
    * EXCEPT (longitude, latitude),
    ST_GEOGPOINT(longitude, latitude) AS geom
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    season = '2020'
    AND basin = 'NA'
    AND name != 'NOT NAMED'
),
dist_between_points AS (
  SELECT
    sid,
    name,
    season,
    -- Calculate distance between consecutive points in kilometers
    ST_DISTANCE(geom, LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time ASC)) / 1000 AS dist
  FROM
    hurricane_geometry
)
SELECT
  sid,
  name,
  -- Sum the distances to get the total distance per hurricane
  SUM(dist) AS total_distance
FROM
  dist_between_points
GROUP BY
  sid,
  name
ORDER BY
  total_distance DESC
LIMIT 100;