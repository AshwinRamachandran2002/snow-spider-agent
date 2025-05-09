-- Latitude of the final reported position for the 2020 North-Atlantic hurricane
-- that covered the 2nd-longest total track distance
WITH atlantic_2020 AS (
  SELECT sid, iso_time, latitude, longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
legs AS (
  SELECT
    sid,
    -- distance (m) between consecutive reports
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) AS leg_m
  FROM atlantic_2020
),
tracks AS (
  SELECT
    sid,
    SUM(leg_m) / 1000 AS total_km          -- convert to kilometres
  FROM legs
  WHERE leg_m IS NOT NULL                  -- ignore first NULL leg
  GROUP BY sid
),
second_longest AS (                        -- SID with 2nd-longest path
  SELECT sid
  FROM tracks
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 1
)
SELECT latitude
FROM atlantic_2020
WHERE sid IN (SELECT sid FROM second_longest)
ORDER BY iso_time DESC
LIMIT 1;