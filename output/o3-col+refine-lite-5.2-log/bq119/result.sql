-- Track of the North‑Atlantic hurricane with the 3rd‑longest path in 2020
WITH fixes AS (  -- all 2020 North‑Atlantic fixes
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time) AS lat_prev,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS lon_prev
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
legs AS (        -- distance (km) between successive fixes
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    IF(
      lat_prev IS NULL,
      0,
      ST_DISTANCE(
        ST_GEOGPOINT(lon_prev, lat_prev),
        ST_GEOGPOINT(longitude, latitude)
      ) / 1000.0               -- metres → kilometres
    ) AS leg_km
  FROM fixes
),
totals AS (      -- total travel of each storm
  SELECT
    sid,
    name,
    SUM(leg_km) AS total_km
  FROM legs
  GROUP BY sid, name
),
third_longest AS (  -- SID of the 3rd‑longest storm
  SELECT sid
  FROM totals
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 2
),
track AS (       -- legs for that storm only
  SELECT l.*
  FROM legs AS l
  JOIN third_longest USING (sid)
)
SELECT
  sid,
  name,
  iso_time,
  latitude,
  longitude,
  ROUND(SUM(leg_km) OVER (PARTITION BY sid ORDER BY iso_time), 2) AS cumulative_distance_km,
  wmo_wind                                         AS max_sustained_wind_knots
FROM track
ORDER BY iso_time;