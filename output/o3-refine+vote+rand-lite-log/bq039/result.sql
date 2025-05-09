-- Top‑10 high–passenger, long‑distance NYC taxi trips between 1‑Jul‑2016 and 7‑Jul‑2016
WITH trips AS (         -- union 2016 yellow & green trips (only fields we need)
  SELECT
    CAST(pickup_location_id  AS STRING) AS pickup_loc,
    CAST(dropoff_location_id AS STRING) AS dropoff_loc,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    CAST(trip_distance AS FLOAT64) AS trip_distance,
    CAST(fare_amount   AS FLOAT64) AS fare_amount,
    CAST(mta_tax       AS FLOAT64) AS mta_tax,
    CAST(tip_amount    AS FLOAT64) AS tip_amount,
    CAST(tolls_amount  AS FLOAT64) AS tolls_amount,
    CAST(total_amount  AS FLOAT64) AS total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`

  UNION ALL

  SELECT
    CAST(pickup_location_id  AS STRING),
    CAST(dropoff_location_id AS STRING),
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    CAST(trip_distance AS FLOAT64),
    CAST(fare_amount   AS FLOAT64),
    CAST(mta_tax       AS FLOAT64),
    CAST(tip_amount    AS FLOAT64),
    CAST(tolls_amount  AS FLOAT64),
    CAST(total_amount  AS FLOAT64)
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
),

filtered AS (           -- apply date, quality & business rules
  SELECT
    *,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS duration_sec
  FROM trips
  WHERE
    pickup_datetime  >= TIMESTAMP('2016-07-01 00:00:00')
    AND pickup_datetime  < TIMESTAMP('2016-07-08 00:00:00')
    AND dropoff_datetime >= TIMESTAMP('2016-07-01 00:00:00')
    AND dropoff_datetime < TIMESTAMP('2016-07-08 00:00:00')
    AND dropoff_datetime  > pickup_datetime                 -- dropoff after pickup
    AND passenger_count  > 5
    AND trip_distance    >= 10
    AND fare_amount      >= 0
    AND mta_tax          >= 0
    AND tip_amount       >= 0
    AND tolls_amount     >= 0
    AND total_amount     >= 0
),

enriched AS (           -- attach zone names & compute metrics
  SELECT
    p.zone_name                         AS pickup_zone,
    d.zone_name                         AS dropoff_zone,
    f.duration_sec,
    f.trip_distance,
    f.total_amount,
    f.tip_amount,
    SAFE_DIVIDE(f.trip_distance, f.duration_sec/3600.0)          AS speed_mph,
    SAFE_DIVIDE(f.tip_amount , NULLIF(f.total_amount,0))*100.0   AS tip_rate_pct
  FROM filtered AS f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
         ON f.pickup_loc  = p.zone_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
         ON f.dropoff_loc = d.zone_id
)

SELECT
  pickup_zone,
  dropoff_zone,
  duration_sec           AS trip_duration_seconds,
  ROUND(speed_mph,      4) AS speed_mph,
  ROUND(tip_rate_pct,   4) AS tip_rate_percent
FROM enriched
ORDER BY total_amount DESC, pickup_zone
LIMIT 10;