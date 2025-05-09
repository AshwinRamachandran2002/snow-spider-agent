WITH base AS (                         -- 1. NA, 2020, main‑track fixes
  SELECT sid, iso_time, latitude, longitude, usa_wind
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND season = '2020'
    AND track_type = 'main'
),
legs AS (                              -- 2. distance between successive fixes (km)
  SELECT *,
         ST_DISTANCE(
           ST_GEOGPOINT(longitude, latitude),
           ST_GEOGPOINT(LAG(longitude) OVER w,
                        LAG(latitude)  OVER w)
         ) / 1000 AS leg_km
  FROM base
  WINDOW w AS (PARTITION BY sid ORDER BY iso_time)
),
totals AS (                            -- 3. total travel distance per storm
  SELECT sid, SUM(leg_km) AS total_km
  FROM legs
  GROUP BY sid
),
ranked AS (                            -- 4. rank storms (longest = 1)
  SELECT sid,
         DENSE_RANK() OVER (ORDER BY total_km DESC) AS rnk
  FROM totals
),
target_sid AS (                        -- 5. pick the 3rd‑longest storm
  SELECT sid
  FROM ranked
  WHERE rnk = 3
),
track AS (                             -- 6. cumulative distance along that storm’s path
  SELECT
    l.iso_time,
    l.latitude,
    l.longitude,
    ROUND(SUM(l.leg_km) OVER (PARTITION BY l.sid ORDER BY l.iso_time), 4)
      AS cumulative_km,
    l.usa_wind
  FROM legs AS l
  JOIN target_sid USING (sid)
)
SELECT                                      -- 7. final output
  FORMAT('%.4f,%.4f', latitude, longitude)         AS travel_coordinates,
  FORMAT('%.4f', cumulative_km)                   AS cumulative_travel_distance_km,
  usa_wind                                        AS max_sustained_wind_speed_kt
FROM track
ORDER BY iso_time;