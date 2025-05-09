WITH trip_counts AS (
  SELECT
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS trip_count
  FROM
    `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  GROUP BY
    trip_date
),
rainy_days AS (
  SELECT DISTINCT date
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = 'USC00305816' AND element = 'PRCP' AND value > 5
)
SELECT
  CASE WHEN r.date IS NOT NULL THEN 'Rainy' ELSE 'Non-rainy' END AS day_type,
  ROUND(AVG(trip_count), 4) AS average_trips
FROM
  trip_counts t
LEFT JOIN
  rainy_days r
ON
  t.trip_date = r.date
GROUP BY
  day_type
ORDER BY
  day_type DESC;