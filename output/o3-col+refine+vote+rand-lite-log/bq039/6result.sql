-- Top-10 highest-fare NYC taxi trips (yellow + green) between
-- 1 Jul 2016 00:00 and 7 Jul 2016 23:59 that meet all stated criteria
WITH candidate_trips AS (
  ------------------------------------------------------------------
  -- YELLOW CABS
  ------------------------------------------------------------------
  SELECT
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    tip_amount,
    total_amount,
    pickup_location_id,
    dropoff_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01'
    AND pickup_datetime  <  '2016-07-08'            -- ensures 1-7 Jul inclusive
    AND dropoff_datetime >= '2016-07-01'
    AND dropoff_datetime <  '2016-07-08'
    AND dropoff_datetime >  pickup_datetime          -- chronology check
    AND passenger_count  >  5
    AND trip_distance    >= 10
    AND fare_amount      >= 0
    AND tip_amount       >= 0
    AND tolls_amount     >= 0
    AND mta_tax          >= 0
    AND total_amount     >= 0
  
  UNION ALL
  
  ------------------------------------------------------------------
  -- GREEN CABS
  ------------------------------------------------------------------
  SELECT
    pickup_datetime,
    dropoff_datetime,
    trip_distance,
    tip_amount,
    total_amount,
    pickup_location_id,
    dropoff_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01'
    AND pickup_datetime  <  '2016-07-08'
    AND dropoff_datetime >= '2016-07-01'
    AND dropoff_datetime <  '2016-07-08'
    AND dropoff_datetime >  pickup_datetime
    AND passenger_count  >  5
    AND trip_distance    >= 10
    AND fare_amount      >= 0
    AND tip_amount       >= 0
    AND tolls_amount     >= 0
    AND mta_tax          >= 0
    AND total_amount     >= 0
)

SELECT
  p.zone_name AS pickup_zone,
  d.zone_name AS dropoff_zone,
  TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)          AS trip_seconds,
  ROUND(
        trip_distance /
        NULLIF(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) / 3600.0 , 0)
       ,2)                                                           AS mph,
  ROUND(tip_amount * 100 / NULLIF(total_amount,0), 2)                AS tip_rate_pct
FROM candidate_trips AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON t.pickup_location_id  = p.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON t.dropoff_location_id = d.zone_id
ORDER BY total_amount DESC
LIMIT 10;