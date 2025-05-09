-- Hurricane track for the storm with the 3rd-longest travel distance  
-- in the North-Atlantic basin during the 2020 season
WITH atl_2020 AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
legs AS (
  -- add segment (leg) distance in km for every consecutive track point
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    COALESCE(
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(
          LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
          LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
        )
      ) / 1000,
      0
    ) AS leg_km
  FROM atl_2020
),
storm_rank AS (
  -- total distance per storm and ranking
  SELECT
    sid,
    SUM(leg_km) AS total_km,
    ROW_NUMBER() OVER (ORDER BY SUM(leg_km) DESC) AS rn
  FROM legs
  GROUP BY sid
),
target_sid AS (
  SELECT sid
  FROM storm_rank
  WHERE rn = 3          -- 3rd-longest overall
),
track AS (
  SELECT
    l.sid,
    l.iso_time,
    l.latitude,
    l.longitude,
    l.wmo_wind,
    l.leg_km,
    SUM(l.leg_km) OVER (PARTITION BY l.sid ORDER BY l.iso_time) AS cumulative_km
  FROM legs AS l
  JOIN target_sid USING (sid)
)
SELECT
  sid                                   AS storm_id,
  iso_time                              AS timestamp,
  latitude,
  longitude,
  ROUND(cumulative_km, 2)               AS cumulative_distance_km,
  wmo_wind                              AS max_sustained_wind_kt
FROM track
ORDER BY timestamp;