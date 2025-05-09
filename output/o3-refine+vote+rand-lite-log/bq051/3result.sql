/*  Average Citi Bike trips per day in 2016, comparing
    “rainy” (> 5 mm total daily precipitation) vs “non‑rainy” days.
*/
WITH
-- 1.  GHCN stations within 50 km of (40.7128,‑74.0060)
station_candidates AS (
  SELECT
    s.id,
    s.name,
    ST_DISTANCE(
      ST_GEOGPOINT(s.longitude, s.latitude),
      ST_GEOGPOINT(-74.0060, 40.7128)
    ) / 1000 AS dist_km          -- convert to kilometres
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations` AS s
  WHERE s.latitude  IS NOT NULL
    AND s.longitude IS NOT NULL
    AND ST_DISTANCE(
          ST_GEOGPOINT(s.longitude, s.latitude),
          ST_GEOGPOINT(-74.0060, 40.7128)
        ) <= 50000              -- 50 km in metres
),

-- 2.  Nearest station that has any valid precipitation data for 2016
valid_station AS (
  SELECT id
  FROM station_candidates AS c
  WHERE EXISTS (
    SELECT 1
    FROM `bigquery-public-data.ghcn_d.ghcnd_*` AS g
    WHERE _TABLE_SUFFIX = '2016'
      AND g.id      = c.id
      AND g.element = 'PRCP'
      AND g.qflag IS NULL
      AND g.mflag IS NULL
      LIMIT 1
  )
  ORDER BY c.dist_km
  LIMIT 1
),

-- 3.  Daily precipitation (tenths‑mm → mm) at that station
daily_precip AS (
  SELECT
    g.date,
    SUM(g.value) / 10.0 AS precipitation_mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_*` AS g
  JOIN valid_station v
    ON g.id = v.id
  WHERE _TABLE_SUFFIX = '2016'
    AND g.element = 'PRCP'
    AND g.qflag IS NULL
    AND g.mflag IS NULL
  GROUP BY g.date
),

-- 4.  Flag each day as rainy/non‑rainy
rain_flag AS (
  SELECT
    date,
    CASE WHEN precipitation_mm > 5 THEN 'rainy' ELSE 'non_rainy' END AS day_type
  FROM daily_precip
),

-- 5.  Citi Bike trips per day in 2016
daily_citibike AS (
  SELECT
    DATE(starttime) AS date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY date
),

-- 6.  Combine weather with trip counts
combined AS (
  SELECT
    cb.date,
    cb.trips,
    rf.day_type
  FROM daily_citibike cb
  JOIN rain_flag    rf USING (date)
)

-- 7.  Final result: average trips by day type
SELECT
  day_type        AS day_category,
  AVG(trips)      AS avg_daily_trips
FROM combined
GROUP BY day_type
ORDER BY day_type;