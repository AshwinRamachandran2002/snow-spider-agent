WITH points AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)  AS prev_lat,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lon
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
segments AS (
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(prev_lon,  prev_lat)
    ) AS metres
  FROM points
  WHERE prev_lat IS NOT NULL
),
totals AS (
  SELECT
    sid,
    SUM(metres) AS total_metres
  FROM segments
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM (
    SELECT
      sid,
      total_metres,
      DENSE_RANK() OVER (ORDER BY total_metres DESC) AS rk
    FROM totals
  )
  WHERE rk = 2
),
last_position AS (
  SELECT
    h.sid,
    h.latitude,
    ROW_NUMBER() OVER (PARTITION BY h.sid ORDER BY h.iso_time DESC) AS rn
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes` h
  JOIN second_longest USING (sid)
)
SELECT ROUND(latitude, 4) AS latitude
FROM last_position
WHERE rn = 1;