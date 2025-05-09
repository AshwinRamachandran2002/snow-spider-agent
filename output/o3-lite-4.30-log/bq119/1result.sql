WITH base AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND season = '2020'
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
segments AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    COALESCE(
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(
          LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
          LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
        )
      ),
      0
    ) AS segment_m
  FROM base
),
totals AS (
  SELECT
    sid,
    SUM(segment_m) AS total_m
  FROM segments
  GROUP BY sid
),
third_sid AS (
  SELECT sid
  FROM totals
  ORDER BY total_m DESC, sid
  LIMIT 1 OFFSET 2   -- third‑longest track
),
path AS (
  SELECT s.*
  FROM segments AS s
  JOIN third_sid USING (sid)
)
SELECT
  CONCAT(CAST(latitude AS STRING), ',', CAST(longitude AS STRING))  AS travel_coordinates,
  ROUND( SUM(segment_m) OVER (PARTITION BY sid ORDER BY iso_time) / 1000, 4 ) AS cumulative_travel_distance_km,
  usa_wind AS max_sustained_wind_speed_kt
FROM path
ORDER BY iso_time;