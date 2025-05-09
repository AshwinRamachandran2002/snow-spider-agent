-- Top 10 high‑fare NYC taxi trips (yellow cabs) between 1–7 July 2016
WITH filtered_trips AS (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    CAST(trip_distance  AS FLOAT64) AS trip_distance,
    CAST(fare_amount   AS FLOAT64) AS fare_amount,
    CAST(tip_amount    AS FLOAT64) AS tip_amount,
    CAST(tolls_amount  AS FLOAT64) AS tolls_amount,
    CAST(mta_tax       AS FLOAT64) AS mta_tax,
    CAST(total_amount  AS FLOAT64) AS total_amount,
    pickup_location_id,
    dropoff_location_id,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS trip_duration_sec
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE
        pickup_datetime  >= '2016-07-01 00:00:00'  -- start of window
    AND pickup_datetime  <  '2016-07-08 00:00:00'  -- end  (exclusive)
    AND dropoff_datetime >= '2016-07-01 00:00:00'
    AND dropoff_datetime <  '2016-07-08 00:00:00'
    AND dropoff_datetime  >  pickup_datetime               -- dropoff after pickup
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0
    AND passenger_count  >  5                               -- more than five riders
    AND CAST(trip_distance AS FLOAT64) >= 10                -- at least 10 miles
    AND CAST(fare_amount   AS FLOAT64) >= 0                 -- no negative charges
    AND CAST(tip_amount    AS FLOAT64) >= 0
    AND CAST(tolls_amount  AS FLOAT64) >= 0
    AND CAST(mta_tax       AS FLOAT64) >= 0
    AND CAST(total_amount  AS FLOAT64) >= 0
)

SELECT
  COALESCE(p.zone_name, 'Unknown') AS pickup_zone,
  COALESCE(d.zone_name, 'Unknown') AS dropoff_zone,
  trip_duration_sec,
  ROUND(trip_distance / (trip_duration_sec/3600.0), 4) AS driving_speed_mph,
  ROUND(tip_amount / NULLIF(total_amount,0) * 100, 4)  AS tip_rate_percentage
FROM filtered_trips AS ft
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON p.zone_id = CAST(ft.pickup_location_id  AS STRING)
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON d.zone_id = CAST(ft.dropoff_location_id AS STRING)
ORDER BY total_amount DESC
LIMIT 10;