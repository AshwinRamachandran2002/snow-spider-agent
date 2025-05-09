-- Hurricane track with the 3rd‑longest total travel distance
-- in the North Atlantic during the 2020 season.
-- Outputs each best‑track position, cumulative distance (km),
-- and maximum sustained (WMO) wind at that time.

WITH atlantic_2020 AS (      -- 2020 best‑track points in the N. Atlantic
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'          -- season year
    AND basin  = 'NA'            -- North Atlantic basin
    AND track_type = 'main'      -- main best‑track only
),

segments AS (                  -- distance between successive points
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    IFNULL(
      ST_DISTANCE(
        ST_GEOGPOINT(LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
                     LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)),
        ST_GEOGPOINT(longitude, latitude)
      ), 0
    ) AS segment_m
  FROM atlantic_2020
),

cumul AS (                     -- cumulative & total distance (km)
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    SUM(segment_m) OVER (PARTITION BY sid ORDER BY iso_time)/1000  AS cum_km,
    SUM(segment_m) OVER (PARTITION BY sid)/1000                   AS total_km
  FROM segments
),

ranked AS (                    -- rank storms by total distance
  SELECT DISTINCT
    sid,
    total_km,
    DENSE_RANK() OVER (ORDER BY total_km DESC) AS dist_rank
  FROM cumul
)

SELECT
  c.sid                                   AS storm_id,
  c.iso_time                              AS time_utc,
  c.latitude,
  c.longitude,
  ROUND(c.cum_km, 2)                      AS cumulative_distance_km,
  c.wmo_wind                              AS max_sustained_wind_kt
FROM cumul AS c
JOIN ranked AS r
  ON c.sid = r.sid
WHERE r.dist_rank = 3                     -- 3rd‑longest track
ORDER BY c.iso_time;