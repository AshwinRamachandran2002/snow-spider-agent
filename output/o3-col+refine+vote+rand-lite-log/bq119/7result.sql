-- Travel track for the 3rd-longest–distance North-Atlantic hurricane of 2020
WITH points AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
segments AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    -- distance (km) from previous reported position
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) / 1000.0 AS segment_km
  FROM points
),
ranked AS (
  SELECT
    sid,
    SUM(segment_km) AS total_km
  FROM segments
  GROUP BY sid
),
third_longest AS (
  SELECT sid
  FROM ranked
  QUALIFY DENSE_RANK() OVER (ORDER BY total_km DESC) = 3
)
SELECT
  s.sid,
  s.name,
  s.iso_time,
  s.latitude,
  s.longitude,
  s.wmo_wind AS max_sustained_wind_kt,
  ROUND(
    SUM(IFNULL(s.segment_km, 0)) OVER (ORDER BY s.iso_time), 2
  ) AS cumulative_distance_km
FROM segments AS s
JOIN third_longest USING (sid)
ORDER BY iso_time;