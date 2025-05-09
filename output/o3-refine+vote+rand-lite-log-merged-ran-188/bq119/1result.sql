-- Hurricane track, cumulative distance and sustained wind for the
-- 3rd–longest-travelled North-Atlantic storm of the 2020 season
WITH ordered AS (                         -- every fix + segment distance
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind,                                            -- sustained wind (kt)
    ST_DISTANCE(
      ST_GeogPoint(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      ),
      ST_GeogPoint(longitude, latitude)
    ) / 1000.0 AS segment_km                             -- km between fixes
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
totals AS (                         -- total travel distance per storm
  SELECT sid, SUM(segment_km) AS total_km
  FROM ordered
  GROUP BY sid
),
third_longest AS (                  -- id of the 3rd-longest storm
  SELECT sid
  FROM totals
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 2
),
track AS (                          -- cumulative distance along the track
  SELECT
    o.sid,
    o.iso_time,
    o.latitude,
    o.longitude,
    SUM(o.segment_km) OVER (PARTITION BY o.sid ORDER BY o.iso_time)
      AS cumulative_km,
    o.usa_wind AS sustained_wind_kt
  FROM ordered o
  JOIN third_longest t USING (sid)
)
SELECT
  sid,
  iso_time,
  latitude,
  longitude,
  ROUND(cumulative_km, 2)      AS cumulative_distance_km,
  sustained_wind_kt            AS max_sustained_wind_kt
FROM track
ORDER BY iso_time;