-- Top-10 highest-fare NYC taxi trips (Yellow + Green) between
-- 1 Jul 2016 and 7 Jul 2016 (inclusive) that carried >5 passengers,
-- travelled ≥10 miles, have non-negative fare components,
-- and have valid pickup / drop-off chronology.
WITH yellow AS (
  SELECT
    pickup_datetime ,
    dropoff_datetime ,
    pickup_location_id ,
    dropoff_location_id ,
    passenger_count ,
    trip_distance ,
    fare_amount ,
    tip_amount ,
    tolls_amount ,
    mta_tax ,
    total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
    AND DATE(dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
),
green AS (
  SELECT
    pickup_datetime ,
    dropoff_datetime ,
    pickup_location_id ,
    dropoff_location_id ,
    passenger_count ,
    trip_distance ,
    fare_amount ,
    tip_amount ,
    tolls_amount ,
    mta_tax ,
    total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE DATE(pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
    AND DATE(dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
),
all_trips AS (
  SELECT * FROM yellow
  UNION ALL
  SELECT * FROM green
),
filtered AS (
  SELECT *
  FROM all_trips
  WHERE dropoff_datetime > pickup_datetime
    AND passenger_count   > 5
    AND trip_distance     >= 10
    AND fare_amount       >= 0
    AND tip_amount        >= 0
    AND tolls_amount      >= 0
    AND mta_tax           >= 0
    AND total_amount      >= 0
)
SELECT
  COALESCE(pickup.zone_name , 'Unknown')   AS pickup_zone ,
  COALESCE(dropoff.zone_name, 'Unknown')   AS dropoff_zone ,
  TIMESTAMP_DIFF(dropoff_datetime , pickup_datetime , SECOND)          AS trip_duration_seconds ,
  ROUND(SAFE_DIVIDE(3600 * trip_distance ,
        NULLIF(TIMESTAMP_DIFF(dropoff_datetime , pickup_datetime , SECOND),0)),2) AS speed_mph ,
  ROUND(100 * SAFE_DIVIDE(tip_amount , NULLIF(total_amount , 0)),2)    AS tip_rate_percent ,
  total_amount
FROM filtered AS t
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS pickup
       ON pickup.zone_id  = t.pickup_location_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  AS dropoff
       ON dropoff.zone_id = t.dropoff_location_id
ORDER BY total_amount DESC
LIMIT 10;