WITH trips AS (
  SELECT
    DATE(pickup_datetime) AS pickup_date,
    EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
    z.zip_code,
    COUNT(*) AS ride_count
  FROM (
    SELECT
      pickup_datetime,
      pickup_longitude,
      pickup_latitude
    FROM
      `bigquery-public-data.new_york.tlc_yellow_trips_2014`
    WHERE
      DATE(pickup_datetime) BETWEEN '2014-12-01' AND '2014-12-31'
      AND pickup_longitude BETWEEN -74.5 AND -73.5
      AND pickup_latitude BETWEEN 40.0 AND 41.0
    UNION ALL
    SELECT
      pickup_datetime,
      pickup_longitude,
      pickup_latitude
    FROM
      `bigquery-public-data.new_york.tlc_yellow_trips_2015`
    WHERE
      DATE(pickup_datetime) BETWEEN '2015-01-01' AND '2015-01-21'
      AND pickup_longitude BETWEEN -74.5 AND -73.5
      AND pickup_latitude BETWEEN 40.0 AND 41.0
  ) AS t
  JOIN
    `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  ON
    ST_CONTAINS(z.zip_code_geom, ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
  GROUP BY
    pickup_date,
    pickup_hour,
    z.zip_code
),
aggregated_trips AS (
  SELECT
    *,
    LAG(ride_count, 1) OVER (PARTITION BY zip_code, pickup_date ORDER BY pickup_hour) AS hourly_lagged_counts,
    LAG(ride_count, 1) OVER (PARTITION BY zip_code, pickup_hour ORDER BY UNIX_DATE(pickup_date)) AS daily_lagged_counts,
    LAG(ride_count, 7) OVER (PARTITION BY zip_code, pickup_hour ORDER BY UNIX_DATE(pickup_date)) AS weekly_lagged_counts,
    ROUND(AVG(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY UNIX_DATE(pickup_date)
      ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING
    ), 4) AS avg14_day_ride_counts,
    ROUND(STDDEV(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY UNIX_DATE(pickup_date)
      ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING
    ), 4) AS stddev14_day_ride_counts,
    ROUND(AVG(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY UNIX_DATE(pickup_date)
      ROWS BETWEEN 21 PRECEDING AND 1 PRECEDING
    ), 4) AS avg21_day_ride_counts,
    ROUND(STDDEV(ride_count) OVER (
      PARTITION BY zip_code, pickup_hour
      ORDER BY UNIX_DATE(pickup_date)
      ROWS BETWEEN 21 PRECEDING AND 1 PRECEDING
    ), 4) AS stddev21_day_ride_counts
  FROM
    trips
)
SELECT
  TIMESTAMP(CONCAT(CAST(pickup_date AS STRING), ' ', CAST(pickup_hour AS STRING), ':00:00')) AS pickup_time,
  zip_code,
  ride_count,
  hourly_lagged_counts,
  daily_lagged_counts,
  weekly_lagged_counts,
  avg14_day_ride_counts,
  stddev14_day_ride_counts,
  avg21_day_ride_counts,
  stddev21_day_ride_counts
FROM
  aggregated_trips
WHERE
  pickup_date = '2015-01-01'
ORDER BY
  ride_count DESC
LIMIT
  5;