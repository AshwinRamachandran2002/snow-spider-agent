WITH trips AS (
  SELECT pickup_datetime, pickup_longitude, pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2014`
  WHERE DATE(pickup_datetime) BETWEEN '2014-12-11' AND '2014-12-31'
    AND pickup_longitude IS NOT NULL AND pickup_latitude IS NOT NULL
    AND pickup_longitude != 0 AND pickup_latitude != 0
  UNION ALL
  SELECT pickup_datetime, pickup_longitude, pickup_latitude
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2015`
  WHERE DATE(pickup_datetime) = '2015-01-01'
    AND pickup_longitude IS NOT NULL AND pickup_latitude IS NOT NULL
    AND pickup_longitude != 0 AND pickup_latitude != 0
),
pickups_with_zip AS (
  SELECT
    pickup_datetime,
    DATE(pickup_datetime) AS pickup_date,
    EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
    z.zip_code
  FROM trips AS t
  JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  ON ST_CONTAINS(z.zip_code_geom, ST_GEOGPOINT(t.pickup_longitude, t.pickup_latitude))
),
counts AS (
  SELECT
    pickup_date,
    pickup_hour,
    zip_code,
    COUNT(*) AS ride_count
  FROM pickups_with_zip
  GROUP BY pickup_date, pickup_hour, zip_code
),
january1_counts AS (
  SELECT *
  FROM counts
  WHERE pickup_date = '2015-01-01'
),
top5 AS (
  SELECT
    pickup_hour,
    zip_code,
    ride_count
  FROM january1_counts
  ORDER BY ride_count DESC
  LIMIT 5
),
counts_prev_hour AS (
  SELECT
    CASE WHEN pickup_hour = 0 THEN DATE_SUB(pickup_date, INTERVAL 1 DAY) ELSE pickup_date END AS pickup_date,
    MOD(pickup_hour + 23, 24) AS pickup_hour,
    zip_code,
    ride_count AS hourly_lagged_counts
  FROM counts
),
counts_prev_day AS (
  SELECT
    DATE_ADD(pickup_date, INTERVAL 1 DAY) AS pickup_date,
    pickup_hour,
    zip_code,
    ride_count AS daily_lagged_counts
  FROM counts
  WHERE pickup_date = DATE_SUB('2015-01-01', INTERVAL 1 DAY)
),
counts_prev_week AS (
  SELECT
    DATE_ADD(pickup_date, INTERVAL 7 DAY) AS pickup_date,
    pickup_hour,
    zip_code,
    ride_count AS weekly_lagged_counts
  FROM counts
  WHERE pickup_date = DATE_SUB('2015-01-01', INTERVAL 7 DAY)
),
avg_counts_14d AS (
  SELECT
    pickup_hour,
    zip_code,
    AVG(ride_count) AS avg_14_day_ride_counts,
    STDDEV(ride_count) AS stddev_14_day_ride_counts
  FROM counts
  WHERE pickup_date BETWEEN DATE_SUB('2015-01-01', INTERVAL 14 DAY) AND DATE_SUB('2015-01-01', INTERVAL 1 DAY)
  GROUP BY pickup_hour, zip_code
),
avg_counts_21d AS (
  SELECT
    pickup_hour,
    zip_code,
    AVG(ride_count) AS avg_21_day_ride_counts,
    STDDEV(ride_count) AS stddev_21_day_ride_counts
  FROM counts
  WHERE pickup_date BETWEEN DATE_SUB('2015-01-01', INTERVAL 21 DAY) AND DATE_SUB('2015-01-01', INTERVAL 1 DAY)
  GROUP BY pickup_hour, zip_code
)
SELECT
  TIMESTAMP(DATETIME(t.pickup_date, TIME(t.pickup_hour, 0, 0))) AS pickup_time,
  t.zip_code,
  t.ride_count,
  COALESCE(h.hourly_lagged_counts, 0) AS hourly_lagged_counts,
  COALESCE(d.daily_lagged_counts, 0) AS daily_lagged_counts,
  COALESCE(w.weekly_lagged_counts, 0) AS weekly_lagged_counts,
  ROUND(a14.avg_14_day_ride_counts, 4) AS avg_14_day_ride_counts,
  ROUND(a14.stddev_14_day_ride_counts, 4) AS stddev_14_day_ride_counts,
  ROUND(a21.avg_21_day_ride_counts, 4) AS avg_21_day_ride_counts,
  ROUND(a21.stddev_21_day_ride_counts, 4) AS stddev_21_day_ride_counts
FROM january1_counts t
JOIN top5 USING(pickup_hour, zip_code)
LEFT JOIN counts_prev_hour h ON t.pickup_date = h.pickup_date AND t.pickup_hour = h.pickup_hour AND t.zip_code = h.zip_code
LEFT JOIN counts_prev_day d ON t.pickup_date = d.pickup_date AND t.pickup_hour = d.pickup_hour AND t.zip_code = d.zip_code
LEFT JOIN counts_prev_week w ON t.pickup_date = w.pickup_date AND t.pickup_hour = w.pickup_hour AND t.zip_code = w.zip_code
LEFT JOIN avg_counts_14d a14 ON t.pickup_hour = a14.pickup_hour AND t.zip_code = a14.zip_code
LEFT JOIN avg_counts_21d a21 ON t.pickup_hour = a21.pickup_hour AND t.zip_code = a21.zip_code
ORDER BY t.ride_count DESC
LIMIT 5;