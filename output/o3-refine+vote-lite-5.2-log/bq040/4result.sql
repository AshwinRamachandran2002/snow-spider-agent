-- Tip–rate distribution for NYC yellow‑cab rides
-- 1 – 7 Jan 2016 (local time), quality filters applied,
-- excluding pick‑ups in the EWR & Staten Island boroughs
WITH trips_filtered AS (
  SELECT
    z.borough                                   AS pickup_borough,
    yt.tip_amount,
    yt.total_amount,
    -- compute percentage the tip represents of the pre‑tip bill
    CASE
      WHEN yt.tip_amount = 0
           OR (yt.total_amount - yt.tip_amount) = 0 THEN 0
      ELSE (yt.tip_amount / (yt.total_amount - yt.tip_amount)) * 100
    END                                         AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS yt
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS z
    ON yt.pickup_location_id = z.zone_id
  WHERE
        -- 1 – 7 Jan 2016
        yt.pickup_datetime >= '2016-01-01 00:00:00'
    AND yt.pickup_datetime <  '2016-01-08 00:00:00'
        -- logical‐quality filters
    AND yt.dropoff_datetime > yt.pickup_datetime
    AND yt.passenger_count > 0
    AND yt.trip_distance      >= 0
    AND yt.tip_amount         >= 0
    AND yt.tolls_amount       >= 0
    AND yt.mta_tax            >= 0
    AND yt.fare_amount        >= 0
    AND yt.total_amount       >= 0
        -- exclude unwanted boroughs
    AND z.borough NOT IN ('EWR','Staten Island')
),
categorized AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_rate = 0               THEN 'no tip'
      WHEN tip_rate <=  5             THEN 'Less than 5%'
      WHEN tip_rate <= 10             THEN '5% to 10%'
      WHEN tip_rate <= 15             THEN '10% to 15%'
      WHEN tip_rate <= 20             THEN '15% to 20%'
      WHEN tip_rate <= 25             THEN '20% to 25%'
      ELSE                                'More than 25%'
    END AS tip_category
  FROM trips_filtered
),
counts AS (
  SELECT
    pickup_borough,
    tip_category,
    COUNT(*) AS ride_cnt
  FROM categorized
  GROUP BY pickup_borough, tip_category
)
SELECT
  pickup_borough,
  tip_category,
  ride_cnt / SUM(ride_cnt) OVER (PARTITION BY pickup_borough) AS proportion_of_rides
FROM counts
ORDER BY pickup_borough, tip_category;