WITH
  trips_data AS (
    SELECT
      DATE(starttime) AS trip_date,
      COUNT(*) AS trip_count
    FROM
      `bigquery-public-data.new_york.citibike_trips`
    WHERE
      EXTRACT(YEAR FROM starttime) = 2016
    GROUP BY
      trip_date
  ),
  weather_data AS (
    SELECT
      DATE(date) AS weather_date,
      MAX(value) / 10.0 AS precipitation_mm
    FROM
      `bigquery-public-data.ghcn_d.ghcnd_2016`
    WHERE
      id = 'USW00094728'
      AND element = 'PRCP'
      AND qflag IS NULL
      AND value IS NOT NULL
    GROUP BY
      weather_date
  ),
  combined_data AS (
    SELECT
      t.trip_date,
      t.trip_count,
      COALESCE(w.precipitation_mm, 0) AS precipitation_mm,
      CASE
        WHEN COALESCE(w.precipitation_mm, 0) > 5 THEN 'Rainy'
        ELSE 'Non-rainy'
      END AS rain_status
    FROM
      trips_data t
    LEFT JOIN
      weather_data w
    ON
      t.trip_date = w.weather_date
  )
SELECT
  rain_status,
  CAST(ROUND(AVG(trip_count)) AS INT64) AS average_daily_trips
FROM
  combined_data
GROUP BY
  rain_status
ORDER BY
  CASE WHEN rain_status = 'Rainy' THEN 1 ELSE 2 END;