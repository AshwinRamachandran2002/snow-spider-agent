/* 1)  Build the 2020 North‑Atlantic tracks
   2)  compute step‑by‑step and total travel distance
   3)  pick the storm whose total distance ranks 3rd longest
   4)  return every track point with cumulative distance (km) and
       maximum sustained wind (WMO wind, in knots)               */
WITH atlantic_2020 AS (          -- positions of every 2020 N‑Atlantic storm
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,                                   -- max. sustained wind
    ST_GEOGPOINT(longitude, latitude) AS pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'            -- North‑Atlantic basin
    AND season = '2020'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
step_dist AS (                   -- distance from previous fix (metres)
  SELECT
    *,
    IFNULL(
      ST_DISTANCE(
        pt,
        LAG(pt) OVER (PARTITION BY sid ORDER BY iso_time)
      ),
      0
    )             AS step_m
  FROM atlantic_2020
),
storm_totals AS (                -- total track length per storm (km)
  SELECT
    sid,
    name,
    SUM(step_m)/1000.0 AS total_km
  FROM step_dist
  GROUP BY sid, name
),
third_longest AS (               -- the 3rd‑longest 2020 Atlantic storm
  SELECT sid, name, total_km
  FROM (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY total_km DESC) AS rnk
    FROM storm_totals
  )
  WHERE rnk = 3
),
chosen_track AS (                -- cumulative distance along that track
  SELECT
    s.sid,
    t.name,
    s.total_km AS storm_total_km,
    t.iso_time,
    t.latitude,
    t.longitude,
    ROUND( SUM(t.step_m) OVER (PARTITION BY t.sid ORDER BY t.iso_time)/1000.0 , 2)
        AS cumulative_km,
    t.wmo_wind                       AS max_sustained_wind_knots
  FROM step_dist t
  JOIN third_longest s
    ON t.sid = s.sid
)
SELECT
  sid,
  name            AS storm_name,
  storm_total_km  AS total_track_km,
  iso_time,
  latitude,
  longitude,
  cumulative_km,
  max_sustained_wind_knots
FROM chosen_track
ORDER BY iso_time;