-- Hurricane track with the 3rd‑longest travel distance in the 2020 North‑Atlantic season
WITH atl_2020 AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lat,
    LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time) AS prev_lon
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'            -- year 2020
    AND basin  = 'NA'              -- North Atlantic basin
    AND track_type = 'main'        -- main best‑track positions only
),
segments AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    -- segment distance in kilometres (0 for the first point or if coords missing)
    CASE
      WHEN prev_lat IS NULL OR prev_lon IS NULL
           OR latitude IS NULL OR longitude IS NULL THEN 0
      ELSE ST_DISTANCE(
             ST_GEOGPOINT(longitude , latitude ),
             ST_GEOGPOINT(prev_lon  , prev_lat )
           ) / 1000
    END AS segment_km
  FROM atl_2020
),
totals AS (
  SELECT
    sid,
    name,
    SUM(segment_km) AS total_km
  FROM segments
  GROUP BY sid, name
),
third_longest AS (         -- identify the hurricane ranked 3rd by total distance
  SELECT sid, name, total_km
  FROM (
    SELECT *,
           RANK() OVER (ORDER BY total_km DESC) AS rnk
    FROM totals
  )
  WHERE rnk = 3
),
track AS (                 -- build the cumulative‑distance track for that hurricane
  SELECT
    s.sid,
    t.name,
    s.iso_time,
    s.latitude,
    s.longitude,
    ROUND( SUM(s.segment_km) OVER (PARTITION BY s.sid ORDER BY s.iso_time), 2) AS cumulative_distance_km,
    s.wmo_wind                    AS max_sustained_wind_knots
  FROM segments AS s
  JOIN third_longest AS t
  USING (sid)
)
SELECT
  sid,
  name,
  iso_time,
  latitude,
  longitude,
  cumulative_distance_km,
  max_sustained_wind_knots
FROM track
ORDER BY iso_time;