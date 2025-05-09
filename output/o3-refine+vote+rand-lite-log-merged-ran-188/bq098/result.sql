-- % of “no-tip” yellow-cab trips by pickup borough  
-- (1 – 7 January 2016, both pickup & drop-off inside the period)

WITH trips AS (
  SELECT
    tz.borough,
    -- tip-rate = 0   ➜   “no-tip” flag = 1
    CASE
      WHEN IFNULL(SAFE_DIVIDE(tip_amount * 100, total_amount), 0) = 0 THEN 1
      ELSE 0
    END AS is_no_tip
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`  AS y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`         AS tz
       ON y.pickup_location_id = tz.zone_id
  WHERE
        -- pickup & drop-off both between 1 Jan and 7 Jan 2016 (inclusive)
        y.pickup_datetime  BETWEEN '2016-01-01'          AND '2016-01-07 23:59:59'
    AND y.dropoff_datetime BETWEEN '2016-01-01'          AND '2016-01-07 23:59:59'
        -- logical trip checks
    AND y.dropoff_datetime > y.pickup_datetime
    AND y.passenger_count  > 0
        -- non-negative monetary / distance fields
    AND y.trip_distance    >= 0
    AND y.tip_amount       >= 0
    AND y.tolls_amount     >= 0
    AND y.mta_tax          >= 0
    AND y.fare_amount      >= 0
    AND y.total_amount     >= 0
)

SELECT
  borough,
  COUNTIF(is_no_tip = 1) AS no_tip_trips,
  COUNT(*)               AS total_trips,
  ROUND(COUNTIF(is_no_tip = 1) * 100.0 / COUNT(*), 2) AS pct_no_tip
FROM trips
GROUP BY borough
ORDER BY pct_no_tip DESC;