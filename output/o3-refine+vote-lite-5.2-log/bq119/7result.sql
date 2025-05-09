/*  Track all 2020 North‑Atlantic storms, rank them by total travel
    distance, take the storm with the 3‑rd longest track, and list
    every fix with cumulative distance (km) and max sustained wind  */
WITH atlantic_2020 AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    COALESCE(usa_wind, wmo_wind) AS max_wind_knots   -- prefer U.S. value
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
track_segments AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    max_wind_knots,
    -- distance to previous fix (metres); first point => NULL
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) AS segment_m
  FROM atlantic_2020
),
total_distance AS (
  SELECT
    sid,
    name,
    SUM(IFNULL(segment_m,0)) AS total_track_m
  FROM track_segments
  GROUP BY sid, name
),
third_longest_sid AS (
  SELECT sid
  FROM total_distance
  ORDER BY total_track_m DESC
  LIMIT 1 OFFSET 2        -- 3rd‑longest (0‑based offset)
),
storm_path AS (
  SELECT
    t.sid,
    t.name,
    t.iso_time,
    t.latitude,
    t.longitude,
    t.max_wind_knots,
    -- cumulative distance so far (km)
    SUM(IFNULL(t.segment_m,0)) OVER (PARTITION BY t.sid ORDER BY t.iso_time)
/ 1000.0 AS cumulative_distance_km
  FROM track_segments AS t
  JOIN third_longest_sid AS s
    ON t.sid = s.sid
)
SELECT
  sid,
  name,
  iso_time,
  latitude,
  longitude,
  ROUND(cumulative_distance_km,4) AS cumulative_distance_km,
  max_wind_knots                  AS max_sustained_wind_knots
FROM storm_path
ORDER BY iso_time;