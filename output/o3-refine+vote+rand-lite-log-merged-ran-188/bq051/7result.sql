/* Average 2016 Citi Bike trips on rainy (> 5 mm) vs. non-rainy days
   using Central Park weather station (ID = USW00094728, ~8 km from NYC
   City Hall) and valid, un-flagged PRCP data. */

WITH precip AS (                     -- rain / non-rain flag by day
  SELECT
    date,
    CASE WHEN value / 10.0 > 5 THEN 'rainy'
         ELSE 'non_rainy' END AS day_type
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id      = 'USW00094728'       -- Central Park station
    AND element = 'PRCP'              -- precipitation
    AND qflag  IS NULL                -- keep only good observations
),

citibike_daily AS (                   -- daily Citi Bike trip totals
  SELECT
    DATE(starttime)     AS ride_date,
    COUNT(*)            AS trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY ride_date
)

SELECT
  p.day_type,
  AVG(cb.trips) AS avg_daily_citibike_trips_2016
FROM precip            AS p
JOIN citibike_daily AS cb
  ON cb.ride_date = p.date
GROUP BY p.day_type
ORDER BY p.day_type;