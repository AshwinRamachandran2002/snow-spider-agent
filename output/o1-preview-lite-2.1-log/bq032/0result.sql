WITH hurricane_points AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    LAG(latitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_latitude,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020' AND basin = 'NA'
),
segment_distances AS (
  SELECT
    sid,
    CASE
      WHEN prev_latitude IS NOT NULL AND prev_longitude IS NOT NULL THEN
        ST_DISTANCE(
          ST_GEOGPOINT(longitude, latitude),
          ST_GEOGPOINT(prev_longitude, prev_latitude)
        )
      ELSE 0
    END AS segment_distance
  FROM hurricane_points
),
total_distances AS (
  SELECT
    sid,
    SUM(segment_distance) AS total_distance
  FROM segment_distances
  GROUP BY sid
),
second_longest_hurricane AS (
  SELECT sid
  FROM (
    SELECT
      sid,
      total_distance,
      ROW_NUMBER() OVER (ORDER BY total_distance DESC) AS rn
    FROM total_distances
  )
  WHERE rn = 2
)
SELECT ROUND(latitude, 4) AS latitude
FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
WHERE sid IN (SELECT sid FROM second_longest_hurricane)
  AND iso_time = (
    SELECT MAX(iso_time)
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE sid IN (SELECT sid FROM second_longest_hurricane)
  )
LIMIT 1;