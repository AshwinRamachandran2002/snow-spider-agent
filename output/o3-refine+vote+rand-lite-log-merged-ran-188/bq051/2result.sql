/*  Average Citi Bike trips on rainy vs non-rainy 2016 days
    – Rainy  = daily precipitation  > 5 mm
    – Non-rainy = daily precipitation ≤ 5 mm
    • Precipitation taken from the single GHCN station that is
      closest (within 50 km) to Times Square (40.7128 N, -74.0060 E)
      and uses only quality-controlled (qflag IS NULL) data.
*/

WITH
-- 1. Nearest GHCN station (within 50 km of Times Square)
nearest_station AS (
  SELECT id
  FROM `bigquery-public-data.ghcn_d.ghcnd_stations`
  WHERE ST_DISTANCE(
          ST_GEOGPOINT(longitude , latitude),
          ST_GEOGPOINT(-74.0060 , 40.7128) ) < 50000      -- 50 km
  ORDER BY ST_DISTANCE(
           ST_GEOGPOINT(longitude , latitude),
           ST_GEOGPOINT(-74.0060 , 40.7128) )
  LIMIT 1
),

-- 2. Daily 2016 precipitation (mm) for that station
daily_prcp AS (
  SELECT
    d.date,
    SUM(d.value) / 10.0 AS prcp_mm               -- convert tenths-mm ➜ mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016` AS d
  JOIN nearest_station            AS s
    ON d.id = s.id
  WHERE d.element = 'PRCP'
    AND d.qflag  IS NULL                         -- keep only valid rows
  GROUP BY d.date
),

-- 3. Daily Citi Bike trip counts for 2016
daily_trips AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips_this_day
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
),

-- 4. Combine trips with precipitation and label rain flag
combined AS (
  SELECT
    t.trip_date,
    t.trips_this_day,
    COALESCE(p.prcp_mm, 0) AS prcp_mm,
    CASE WHEN COALESCE(p.prcp_mm, 0) > 5
         THEN 'RAINY' ELSE 'NON_RAINY' END AS rain_flag
  FROM daily_trips AS t
  LEFT JOIN daily_prcp AS p
         ON t.trip_date = p.date
)

-- 5. Average trips for rainy vs non-rainy days
SELECT
  rain_flag,
  ROUND(AVG(trips_this_day), 4) AS avg_daily_trips
FROM combined
GROUP BY rain_flag
ORDER BY rain_flag;