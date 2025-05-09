-- Hurricane track and cumulative‑distance details
-- for the North Atlantic storm that had the third‑longest
-- total travel distance during the 2020 season
WITH atlantic_2020 AS (          -- points for every 2020 North‑Atlantic storm
  SELECT
    sid,
    iso_time,                    -- timestamp of fix
    latitude,
    longitude,
    COALESCE(usa_wind , wmo_wind) AS wind_knots        -- sustained wind (knots)
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'             -- North Atlantic basin
    AND season = '2020'          -- season (calendar year)
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
ordered AS (                     -- add previous‑point coordinates
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wind_knots,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lat,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lon
  FROM atlantic_2020
),
segments AS (                    -- segment length (km) between fixes
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wind_knots,
    IF(prev_lat IS NULL, 0,
       ST_DISTANCE(
         ST_GEOGPOINT(prev_lon , prev_lat),
         ST_GEOGPOINT(longitude, latitude)
       ) / 1000.0
    ) AS segment_km
  FROM ordered
),
total_distances AS (             -- total travel distance per storm
  SELECT
    sid,
    SUM(segment_km) AS total_km
  FROM segments
  GROUP BY sid
),
third_longest_sid AS (           -- id of the 3rd‑longest track
  SELECT sid
  FROM total_distances
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 2               -- 0‑based: 0‑longest, 1‑second, 2‑third
),
cumulative AS (                  -- cumulative distance for every fix
  SELECT
    s.sid,
    s.iso_time,
    s.latitude,
    s.longitude,
    s.wind_knots,
    SUM(s.segment_km) OVER (PARTITION BY s.sid ORDER BY s.iso_time) AS cumulative_km
  FROM segments s
)
SELECT
  sid,
  iso_time                       AS track_timestamp,
  latitude,
  longitude,
  ROUND(cumulative_km , 2)       AS cumulative_distance_km,
  wind_knots                     AS max_sustained_wind_knots
FROM cumulative
WHERE sid IN (SELECT sid FROM third_longest_sid)
ORDER BY iso_time;