-- Travel log for the hurricane with the 3-rd longest 2020 North-Atlantic track
WITH atl_2020 AS (                 -- every 2020 North-Atlantic position fix
  SELECT sid, iso_time, latitude, longitude, usa_wind
  FROM  `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA' AND season = '2020'
),
-- distance of each leg (km) for every storm
legs AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    usa_wind,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      LAG(ST_GEOGPOINT(longitude, latitude))
        OVER (PARTITION BY sid ORDER BY iso_time)
    ) / 1000.0 AS leg_km            -- metres → kilometres
  FROM atl_2020
),
-- total travel distance per storm
totals AS (
  SELECT sid,
         SUM(leg_km) AS total_km
  FROM  legs
  WHERE leg_km IS NOT NULL
  GROUP BY sid
),
-- SID of the storm with the 3-rd longest track
third_sid AS (
  SELECT sid
  FROM totals
  ORDER BY total_km DESC
  LIMIT 1 OFFSET 2                  -- 0-based: 0-longest, 1-second, 2-third
)
-- final ordered travel log for that storm
SELECT
  l.iso_time,
  l.latitude,
  l.longitude,
  ROUND(                       -- cumulative distance so far
    SUM(IFNULL(l.leg_km,0))
      OVER (ORDER BY l.iso_time), 1
  ) AS cumulative_km,
  l.usa_wind AS max_sustained_wind_kt
FROM legs AS l
JOIN third_sid USING (sid)
ORDER BY l.iso_time;