WITH na2020 AS (
  SELECT sid, iso_time, latitude, longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
    AND track_type = 'main'
),
legs AS (
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) AS leg_m
  FROM na2020
),
totals AS (
  SELECT sid, SUM(leg_m) AS total_m
  FROM legs
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM (
    SELECT
      sid,
      DENSE_RANK() OVER (ORDER BY total_m DESC) AS rnk
    FROM totals
  )
  WHERE rnk = 2
),
last_fix AS (
  SELECT
    ROUND(latitude, 4) AS latitude,
    ROW_NUMBER() OVER (ORDER BY iso_time DESC) AS rn
  FROM na2020
  WHERE sid IN (SELECT sid FROM second_longest)
)
SELECT latitude
FROM last_fix
WHERE rn = 1;