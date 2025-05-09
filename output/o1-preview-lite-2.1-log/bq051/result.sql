WITH precipitation AS (
  SELECT date,
    CASE WHEN value / 10 > 0.5 THEN 'Rainy' ELSE 'Non-rainy' END AS day_type
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = 'USW00094728'
    AND element = 'PRCP'
    AND value IS NOT NULL
    AND EXTRACT(YEAR FROM date) = 2016
),
trip_counts AS (
  SELECT
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS trip_count
  FROM (
    SELECT pickup_datetime FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
    UNION ALL
    SELECT pickup_datetime FROM `bigquery-public-data.new_york.tlc_green_trips_2016`
    UNION ALL
    SELECT pickup_datetime FROM `bigquery-public-data.new_york.tlc_fhv_trips_2016`
  )
  WHERE EXTRACT(YEAR FROM pickup_datetime) = 2016
  GROUP BY trip_date
)
SELECT
  precipitation.day_type,
  CAST(ROUND(AVG(trip_counts.trip_count)) AS INT64) AS average_trips
FROM trip_counts
JOIN precipitation ON trip_counts.trip_date = precipitation.date
GROUP BY precipitation.day_type
ORDER BY precipitation.day_type;