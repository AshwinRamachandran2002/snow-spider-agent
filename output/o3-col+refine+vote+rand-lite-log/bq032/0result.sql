-- latitude of the last reported position for the 2020 North-Atlantic storm
-- that travelled the 2nd-longest total distance
WITH legs AS (
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) / 1000.0 AS leg_km
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
totals AS (
  SELECT sid, SUM(leg_km) AS total_km
  FROM legs
  WHERE leg_km IS NOT NULL
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM (
    SELECT sid,
           DENSE_RANK() OVER (ORDER BY total_km DESC) AS rnk
    FROM totals
  )
  WHERE rnk = 2
),
final_fix AS (
  SELECT
    sid,
    latitude,
    ROW_NUMBER() OVER (PARTITION BY sid ORDER BY iso_time DESC) AS rn
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE sid IN (SELECT sid FROM second_longest)
)
SELECT latitude AS final_latitude
FROM final_fix
WHERE rn = 1;