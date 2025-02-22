-- Task: For each hurricane in the North Atlantic during 2020, provide the distances in kilometers between consecutive points along their paths. Limit the output to 100 rows.

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
    iso_time,
    usa_wind,
    geom,
    ST_DISTANCE(
      geom,
      LAG(geom, 1) OVER (PARTITION BY sid ORDER BY iso_time ASC)
    ) / 1000 AS dist
  FROM
    hurricane_geometry
)

SELECT
  sid,
  name,
  season,
  iso_time,
  usa_wind,
  geom,
  dist
FROM
  dist_between_points
ORDER BY
  sid,
  iso_time
LIMIT 100;