-- 1) Find the 2020 North-Atlantic hurricane with the 3rd-longest travelled distance
-- 2) Return its chronological fixes (coords), running cumulative distance (km),
--    and sustained wind speed at each fix
WITH points AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lat,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lon
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'        -- study year
    AND basin  = 'NA'          -- North Atlantic
    AND track_type = 'main'    -- main track only
),
segments AS (                   -- distance between successive fixes
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    COALESCE(
      ST_DISTANCE(
        ST_GEOGPOINT(prev_lon, prev_lat),
        ST_GEOGPOINT(longitude, latitude)
      ) / 1000,                -- km
      0
    ) AS segment_km
  FROM points
),
totals AS (                     -- total km per storm
  SELECT
    sid,
    name,
    SUM(segment_km) AS total_km
  FROM segments
  GROUP BY sid, name
),
the_storm AS (                  -- 3rd-longest in 2020 NA basin
  SELECT sid
  FROM totals
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 2              -- 0-based offset: 0=longest, 1=2nd, 2=3rd
),
path AS (                       -- cumulative distance for that storm
  SELECT
    s.sid,
    s.name,
    s.iso_time,
    s.latitude,
    s.longitude,
    ROUND(
      SUM(segment_km) OVER (ORDER BY iso_time), 2
    ) AS cumulative_km,
    s.usa_wind AS sustained_wind_knots
  FROM segments s
  JOIN the_storm t
    ON s.sid = t.sid
)
SELECT
  sid,
  name,
  iso_time,
  latitude,
  longitude,
  cumulative_km,
  sustained_wind_knots
FROM path
ORDER BY iso_time;