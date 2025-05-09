WITH weather AS (
  SELECT
    date,
    CASE
      WHEN value / 10 > 0.5 THEN 'Rainy'
      ELSE 'Non-rainy'
    END AS day_type
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE
    id = 'USW00094728'  -- Closest station to the specified coordinates
    AND element = 'PRCP'
    AND value IS NOT NULL
),
trip_data AS (
  SELECT
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS num_trips
  FROM
    `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE
    EXTRACT(YEAR FROM pickup_datetime) = 2016
    AND pickup_datetime IS NOT NULL
  GROUP BY
    trip_date
),
trip_weather AS (
  SELECT
    td.trip_date,
    w.day_type,
    td.num_trips
  FROM
    trip_data td
  JOIN
    weather w
  ON
    td.trip_date = w.date
)
SELECT
  day_type,
  ROUND(AVG(num_trips), 4) AS average_trips
FROM
  trip_weather
GROUP BY
  day_type;