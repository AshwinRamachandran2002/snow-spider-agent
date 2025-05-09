WITH citibike_daily_trips AS (
  SELECT DATE(starttime) AS trip_date, COUNT(*) AS trip_count
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY trip_date
),

precipitation_data AS (
  SELECT date, CAST(value AS FLOAT64) / 10 AS precipitation_mm
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = 'USW00094728' AND element = 'PRCP' AND qflag IS NULL
)

SELECT
  rain_status,
  ROUND(AVG(trip_count), 4) AS average_daily_trips
FROM (
  SELECT
    t.trip_date,
    t.trip_count,
    IF(p.precipitation_mm > 5, 'Rainy', 'Non-rainy') AS rain_status
  FROM citibike_daily_trips AS t
  LEFT JOIN precipitation_data AS p
    ON t.trip_date = p.date
)
GROUP BY rain_status
ORDER BY CASE WHEN rain_status = 'Rainy' THEN 1 ELSE 2 END;