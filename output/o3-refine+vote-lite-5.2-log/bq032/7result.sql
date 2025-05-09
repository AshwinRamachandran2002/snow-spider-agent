WITH atlantic_2020 AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS point
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin = 'NA'          -- North Atlantic basin
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
track_segments AS (
  SELECT
    sid,
    ST_DISTANCE(
      point,
      LAG(point) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS segment_distance
  FROM atlantic_2020
),
storm_totals AS (
  SELECT
    sid,
    SUM(segment_distance) AS total_distance_m
  FROM track_segments
  GROUP BY sid
),
second_longest AS (
  SELECT sid
  FROM storm_totals
  ORDER BY total_distance_m DESC
  LIMIT 1 OFFSET 1           -- 2nd‑longest distance
),
final_coord AS (
  SELECT
    a.sid,
    a.latitude,
    ROW_NUMBER() OVER (PARTITION BY a.sid ORDER BY a.iso_time DESC) AS rn
  FROM atlantic_2020 a
  JOIN second_longest b
  USING (sid)
)
SELECT latitude
FROM final_coord
WHERE rn = 1;