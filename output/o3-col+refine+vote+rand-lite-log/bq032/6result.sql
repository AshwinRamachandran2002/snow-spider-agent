-- latitude of the last reported position for the hurricane
-- that covered the 2nd-longest track in the North Atlantic in 2020
WITH points AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS pt,
    LAG(ST_GEOGPOINT(longitude, latitude))
        OVER (PARTITION BY sid ORDER BY iso_time) AS prev_pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
legs AS (
  SELECT
    sid,
    ST_DISTANCE(pt, prev_pt) AS leg_m
  FROM points
  WHERE prev_pt IS NOT NULL
),
tracks AS (
  SELECT
    sid,
    SUM(leg_m) AS total_m
  FROM legs
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM tracks
  ORDER BY total_m DESC
  LIMIT 1 OFFSET 1          -- the 2nd-longest track
)
SELECT latitude
FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
WHERE sid IN (SELECT sid FROM second_longest)
  AND season = '2020'
  AND basin  = 'NA'
ORDER BY iso_time DESC       -- latest position
LIMIT 1;