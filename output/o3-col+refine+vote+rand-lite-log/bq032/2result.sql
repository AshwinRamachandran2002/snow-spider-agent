WITH na_2020 AS (
  SELECT sid, iso_time, latitude, longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
leg_distances AS (
  SELECT
    sid,
    -- distance (km) between successive fixes
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) / 1000 AS leg_km
  FROM na_2020
),
storm_totals AS (
  SELECT
    sid,
    SUM(leg_km) AS total_km
  FROM leg_distances
  WHERE leg_km IS NOT NULL
  GROUP BY sid
),
second_longest AS (          -- SID that travelled the 2nd-longest distance
  SELECT sid
  FROM storm_totals
  QUALIFY DENSE_RANK() OVER (ORDER BY total_km DESC) = 2
)
SELECT latitude
FROM na_2020
JOIN second_longest USING (sid)
ORDER BY iso_time DESC          -- final (latest) track point
LIMIT 1;