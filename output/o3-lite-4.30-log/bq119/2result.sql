WITH base AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    ST_GEOGPOINT(longitude, latitude) AS geo
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND season = '2020'
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
legs AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    ST_DISTANCE(
      geo,
      LAG(geo) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS leg_m
  FROM base
),
totals AS (
  SELECT
    sid,
    SUM(leg_m) AS total_m
  FROM legs
  GROUP BY sid
),
third_sid AS (
  SELECT sid
  FROM totals
  ORDER BY total_m DESC, sid
  LIMIT 1 OFFSET 2          -- third‑longest traveller
),
track AS (
  SELECT
    l.iso_time,
    l.latitude,
    l.longitude,
    l.usa_wind,
    SUM(IFNULL(l.leg_m,0)) OVER (PARTITION BY l.sid ORDER BY l.iso_time) / 1000.0 AS cumulative_km
  FROM legs l
  JOIN third_sid t
  ON l.sid = t.sid
)
SELECT
  ST_ASTEXT(ST_GEOGPOINT(longitude, latitude)) AS travel_coordinates,
  ROUND(cumulative_km,4)                       AS cumulative_travel_distance_km,
  usa_wind                                     AS max_sustained_wind_speed_kt
FROM track
ORDER BY iso_time;