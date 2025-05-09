-- Chronological track for the North-Atlantic 2020 storm that had the
-- 3rd-longest total travel distance.  For each advisory the query shows
-- the position, cumulative distance travelled (km), and maximum sustained
-- wind speed (kt).

WITH atl_2020 AS (           -- 1.  All 2020 North-Atlantic fixes
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind,                                -- max sustained wind (kt)
    ST_GEOGPOINT(longitude, latitude) AS geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin IN ('NA','AL')                 -- Atlantic basin codes
),

legs AS (                -- 2.  Leg length (km) between successive fixes
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    ST_DISTANCE(
      geom,
      LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) / 1000.0 AS leg_km                     -- metres → kilometres
  FROM atl_2020
),

totals AS (              -- 3.  Total travel distance per storm
  SELECT
    sid,
    SUM(IFNULL(leg_km,0)) AS total_km
  FROM legs
  GROUP BY sid
),

third_longest AS (       -- 4.  Identify the 3rd-longest-travelled storm
  SELECT sid
  FROM (
    SELECT
      sid,
      total_km,
      ROW_NUMBER() OVER (ORDER BY total_km DESC) AS rn
    FROM totals
  )
  WHERE rn = 3
),

chosen_track AS (        -- 5.  Cumulative distance along that storm’s track
  SELECT
    l.iso_time,
    l.latitude,
    l.longitude,
    l.wmo_wind,
    SUM(IFNULL(l.leg_km,0)) OVER (ORDER BY l.iso_time) AS cumulative_km
  FROM legs AS l
  JOIN third_longest AS t
  ON l.sid = t.sid
)

-- 6.  Final ordered output
SELECT
  iso_time,
  latitude,
  longitude,
  ROUND(cumulative_km,1)   AS cumulative_distance_km,
  wmo_wind                 AS max_sustained_wind_kt
FROM chosen_track
ORDER BY iso_time;