-- latitude of the last fix for the 2020 North‑Atlantic storm
-- that travelled the 2nd‑longest total distance
WITH leg_distances AS (
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) / 1000 AS leg_km      -- km between successive fixes
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
totals AS (
  SELECT sid, SUM(leg_km) AS total_km
  FROM leg_distances
  WHERE leg_km IS NOT NULL
  GROUP BY sid
),
second_longest_sid AS (
  SELECT sid
  FROM totals
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 1          -- 2nd‑longest
)
SELECT latitude
FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
WHERE sid IN (SELECT sid FROM second_longest_sid)
  AND season = '2020'
  AND basin  = 'NA'
ORDER BY iso_time DESC
LIMIT 1;