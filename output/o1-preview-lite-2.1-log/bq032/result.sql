WITH hurricane_tracks AS (
  SELECT
    sid,
    name,
    latitude,
    longitude,
    iso_time,
    LAG(latitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_latitude,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020' AND basin = 'NA'
),
hurricane_distances AS (
  SELECT
    sid,
    name,
    SUM(ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(prev_longitude, prev_latitude)
    )) AS total_distance
  FROM hurricane_tracks
  WHERE prev_latitude IS NOT NULL AND prev_longitude IS NOT NULL
  GROUP BY sid, name
),
second_longest_hurricane AS (
  SELECT sid
  FROM hurricane_distances
  ORDER BY total_distance DESC
  LIMIT 1 OFFSET 1
),
final_position AS (
  SELECT
    h.sid,
    h.name,
    ROUND(h.latitude, 4) AS latitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes` h
  JOIN second_longest_hurricane s ON h.sid = s.sid
  WHERE h.season = '2020' AND h.basin = 'NA'
  ORDER BY h.iso_time DESC
  LIMIT 1
)
SELECT latitude
FROM final_position;