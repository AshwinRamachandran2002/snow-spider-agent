-- Description: Identify the 2020 North-Atlantic hurricane with the 3rd-longest
--              total travel distance, then list every track point together
--              with its coordinates, cumulative distance (km), and sustained
--              wind speed (knots).

WITH atl_2020 AS (   -- All 2020 North-Atlantic track points
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind              -- sustained wind (knots)
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),

trk_prev AS (         -- Add previous point for each storm
  SELECT
    sid, iso_time, latitude, longitude, wmo_wind,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lat,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lon
  FROM atl_2020
),

segs AS (             -- Segment distance (km) between successive points
  SELECT
    sid, iso_time, latitude, longitude, wmo_wind,
    IF(prev_lat IS NULL, 0,
       ST_DISTANCE(
         ST_GEOGPOINT(longitude , latitude ),
         ST_GEOGPOINT(prev_lon  , prev_lat )
       ) / 1000.0)                       AS seg_km
  FROM trk_prev
),

totals AS (           -- Total travel distance per storm
  SELECT
    sid,
    SUM(seg_km) AS total_km
  FROM segs
  GROUP BY sid
),

third_storm AS (      -- Storm ranked 3rd longest
  SELECT sid
  FROM (
    SELECT
      sid,
      total_km,
      RANK() OVER (ORDER BY total_km DESC) AS rnk
    FROM totals
  )
  WHERE rnk = 3
),

chosen_track AS (     -- Track points for the 3rd-longest storm
  SELECT s.*
  FROM segs  AS s
  JOIN third_storm USING (sid)
)

SELECT
  sid,
  iso_time,
  latitude,
  longitude,
  ROUND(SUM(seg_km) OVER (ORDER BY iso_time), 1) AS cumulative_km,
  wmo_wind                                       AS sustained_wind_knots
FROM chosen_track
ORDER BY iso_time;