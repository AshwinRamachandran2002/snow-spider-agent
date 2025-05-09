-- latitude of the last reported point for the hurricane that
-- travelled the 2nd-longest distance in the North Atlantic in 2020
WITH na_2020 AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
legs AS (
  SELECT
    sid,
    ST_DISTANCE(
      pt,
      LAG(pt) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS leg_m
  FROM na_2020
),
path_lengths AS (
  SELECT
    sid,
    SUM(IFNULL(leg_m,0)) AS total_m
  FROM legs
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM (
    SELECT
      sid,
      DENSE_RANK() OVER (ORDER BY total_m DESC) AS rnk
    FROM path_lengths
  )
  WHERE rnk = 2
),
last_point AS (
  SELECT
    h.sid,
    h.latitude,
    ROW_NUMBER() OVER (PARTITION BY h.sid ORDER BY h.iso_time DESC) AS rn
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
  JOIN second_longest USING (sid)
)
SELECT ROUND(latitude, 4) AS latitude
FROM last_point
WHERE rn = 1;