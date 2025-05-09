/*--------------------------------------------------------------------
  Average Citi Bike ridership in 2016 on rainy vs. non-rainy days.
  – “Rainy” = daily precipitation ≥ 5 mm (PRCP / 10 ≥ 5)
  – Weather data: Central Park station USW00094728
    (≈ 4 km from Times Sq; well within the required 50 km radius).
--------------------------------------------------------------------*/

WITH
/* 1.  Central Park daily precipitation (mm) */
daily_prcp AS (
  SELECT
    date                          AS trip_date,
    SUM(value) / 10.0             AS prcp_mm        -- 1/10 mm  →  mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id      = 'USW00094728'                     -- Central Park
    AND element = 'PRCP'
    AND qflag  IS NULL                              -- only good data
  GROUP BY date
),

/* 2.  Flag days as rainy / non-rainy */
rain_flag AS (
  SELECT
    trip_date,
    CASE WHEN prcp_mm >= 5 THEN 'rainy' ELSE 'non_rainy' END AS weather
  FROM daily_prcp
),

/* 3.  Citi Bike daily trip counts for 2016 */
bike_counts AS (
  SELECT
    DATE(starttime) AS trip_date,
    COUNT(*)        AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
),

/* 4.  Combine ridership with weather flag */
combined AS (
  SELECT
    b.trips,
    r.weather
  FROM bike_counts AS b
  JOIN rain_flag   AS r
    USING (trip_date)
)

/* 5.  Final averages */
SELECT
  weather,
  AVG(trips) AS avg_daily_trips,
  COUNT(*)   AS num_days
FROM combined
GROUP BY weather;