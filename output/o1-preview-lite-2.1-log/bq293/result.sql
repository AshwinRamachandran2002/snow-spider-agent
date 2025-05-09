WITH trips AS (
  SELECT
    pickup_datetime,
    pickup_longitude,
    pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2014`
  UNION ALL
  SELECT
    pickup_datetime,
    pickup_longitude,
    pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
),
trips_in_period AS (
  SELECT
    pickup_datetime,
    pickup_longitude,
    pickup_latitude
  FROM trips
  WHERE DATE(pickup_datetime) BETWEEN DATE_SUB('2015-01-01', INTERVAL 21 DAY) AND '2015-01-01'
    AND pickup_longitude != 0 AND pickup_latitude != 0
),
trips_with_zip AS (
  SELECT
    t.pickup_datetime,
    EXTRACT(DATE FROM t.pickup_datetime) AS pickup_date,
    EXTRACT(HOUR FROM t.pickup_datetime) AS pickup_hour,
    t.pickup_longitude,
    t.pickup_latitude,
    z.zip_code
  FROM trips_in_period AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
    ON ST_CONTAINS(z.zip_code_geom, ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
),
aggregated_trips AS (
  SELECT
    pickup_date,
    pickup_hour,
    zip_code,
    COUNT(*) AS ride_count
  FROM trips_with_zip
  GROUP BY pickup_date, pickup_hour, zip_code
),
metrics AS (
  SELECT
    pickup_date,
    pickup_hour,
    zip_code,
    ride_count,
    LAG(ride_count) OVER (
      PARTITION BY zip_code
      ORDER BY pickup_date, pickup_hour
    ) AS hourly_lagged_counts,
    LAG(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
    ) AS daily_lagged_counts,
    LAG(ride_count, 7) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
    ) AS weekly_lagged_counts,
    ROUND(AVG(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
      ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
    ), 4) AS `14_day_avg_ride_counts`,
    ROUND(STDDEV(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
      ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
    ), 4) AS `14_day_stddev_ride_counts`,
    ROUND(AVG(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
      ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
    ), 4) AS `21_day_avg_ride_counts`,
    ROUND(STDDEV(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY pickup_date
      ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
    ), 4) AS `21_day_stddev_ride_counts`
  FROM aggregated_trips
)
SELECT
  TIMESTAMP(CONCAT(CAST(pickup_date AS STRING), ' ', CAST(pickup_hour AS STRING), ':00:00')) AS pickup_time,
  zip_code,
  ride_count,
  hourly_lagged_counts,
  daily_lagged_counts,
  weekly_lagged_counts,
  `14_day_avg_ride_counts`,
  `14_day_stddev_ride_counts`,
  `21_day_avg_ride_counts`,
  `21_day_stddev_ride_counts`
FROM metrics
WHERE pickup_date = '2015-01-01'
ORDER BY ride_count DESC
LIMIT 5;