-- Hurricane track and cumulative distance for the storm with the
-- 3-rd longest North-Atlantic track in the 2020 season
WITH na_2020 AS (      -- all 2020 North-Atlantic fixes
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS geo
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
-- segment lengths (km) between successive fixes for every storm
seg AS (
  SELECT
    sid,
    ST_DISTANCE(
      geo,
      LAG(geo) OVER (PARTITION BY sid ORDER BY iso_time)
    ) / 1000 AS seg_km
  FROM na_2020
),
-- total distance per storm
totals AS (
  SELECT sid, SUM(seg_km) AS total_km
  FROM seg
  GROUP BY sid
),
-- SID of the storm with the 3-rd longest track
third_longest AS (
  SELECT sid
  FROM (
    SELECT sid,
           DENSE_RANK() OVER (ORDER BY total_km DESC) AS rk
    FROM totals
  )
  WHERE rk = 3
),
-- bring back full track for that storm
track AS (
  SELECT
    h.sid,
    h.iso_time,
    h.latitude,
    h.longitude,
    h.wmo_wind,
    ST_GEOGPOINT(h.longitude, h.latitude)                       AS geo,
    LAG(ST_GEOGPOINT(h.longitude, h.latitude))
        OVER (PARTITION BY h.sid ORDER BY h.iso_time)           AS prev_geo
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes` h
  WHERE h.sid IN (SELECT sid FROM third_longest)
)
SELECT
  iso_time,
  latitude,
  longitude,
  ROUND(
    SUM( ST_DISTANCE(geo, prev_geo) / 1000 )
      OVER (PARTITION BY sid ORDER BY iso_time)
  , 2)                                                        AS cumulative_distance_km,
  wmo_wind                                                   AS max_sustained_wind_kt
FROM track
ORDER BY iso_time;